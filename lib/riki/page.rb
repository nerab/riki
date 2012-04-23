require 'cgi'
require 'date'

module Riki
  #
  # Represents a MediaWiki page. Only the latest revision of a page is considered.
  #
  class Page < Base
    class << self
      def find_by_title(titles)
        titles = Array(titles) # always treat titles as array
        return [] if titles.empty?

        results = {}

        # find cached pages
        titles.each{|title|
          cached = Riki::Base.cache.read(cache_key("page_#{title}"))
          if cached
            results[title] = cached
            Riki.logger.info "Found cached version of requested page #{title} as '#{cached.title}'"
          end
        }

        # Check _in one coarse-grained API call which cached pages are still current
        if results.any?
          query = retrieve_pages(results.keys, 'timestamp')
          query.find('m:pages/m:page').each{|page|
            title = page['title'] # will already be the normalized and redirected title

            # Make sure redirects and normalizations are still current
            if indirection = normalization(query, title) || redirection(query, title)
              if Riki::Base.cache.read(cache_key("page_#{indirection['from']}")).title != indirection['to']
                Riki.logger.info "Redirection source #{indirection['from']} is stale. New target is #{indirection['to']}"
                results.delete(indirection['from'])
                titles.delete(indirection['from'])
                Riki::Base.cache.delete(cache_key("page_#{indirection['from']}"))

                # Re-check whether we have the new indirection target in our cache
                if cached_indirection_to = Riki::Base.cache.read(cache_key("page_#{indirection['to']}"))
                  results[title] = cached_indirection_to
                else
                  titles << indirection['to']
                end
              else
                Riki.logger.info "Redirection is still current, no need to re-fetch #{indirection['from']}"
                titles.delete(indirection['from'])
              end
            end

            if results[title] # anything left to check after resolving indirections?
              last_modified = DateTime.strptime(page.find_first('m:revisions/m:rev')['timestamp'], '%Y-%m-%dT%H:%M:%S%Z')
              if last_modified < results[title].last_modified
                Riki.logger.info "Cached version of page '#{title}' is from #{results[title].last_modified}, but an updated version is available that dates #{last_modified}"
                results.delete(title)
              else
                Riki.logger.info "Cached version of page '#{title}' is still current. No need to re-fetch."
                titles.delete(title)
              end
            end
          }
        end

        Riki.logger.info "Currency check leaves these pages to retrieve in full: #{titles.join(', ')}"

        return results.values if titles.empty? # no titles asked for or all results cached and current

        query = retrieve_pages(titles, ['content', 'timestamp'])
        query.find('m:pages/m:page').each{|page|
          if page['missing']
            Riki.logger.info "Page '#{page['title']}' was not found"
            next
          end

          validate!(page)

          p = Page.new(page['title'])

          p.id = page['pageid'].to_i
          p.namespace = page['ns']

          rev = page.find_first('m:revisions/m:rev')
          p.content = rev.content
          p.last_modified = DateTime.strptime(rev['timestamp'], '%Y-%m-%dT%H:%M:%S%Z')

          Riki::Base.cache.write(cache_key("page_#{p.title}"), p)
          Riki.logger.info "Page '#{p.title}' written to the cache"

          # Cache the non-normalized form so that the next query will hit the cache even if asking for the non-normalized version
          # <normalized><n from="ISO_639-2" to="ISO 639-2" /></normalized>
          normalization = normalization(query, p.title)

          if normalization
            Riki.logger.info "Also caching page '#{p.title}' under its non-normalized title '#{normalization['from']}'"
            p.normalized_from = normalization['from']

            # TODO We might save some space by caching a flyweight of p here (like an alias)
            Riki::Base.cache.write(cache_key("page_#{p.normalized_from}"), p)
          end

          # Cache the page under the title of the redirect source
          # <redirects><r from="&quot;Mimia&quot;" to="Mimipiscis" tofragment=""/>
          redirection = redirection(query, p.title)

          if redirection
            Riki.logger.info "Also caching page '#{p.title}' under its redirect source '#{redirection['from']}'"
            p.redirected_from = redirection['from']

            # TODO We might save some space by caching a flyweight of p here (like an alias)
            Riki::Base.cache.write(cache_key("page_#{p.redirected_from}"), p)
          end

          results[p.title] = p
        }

        results.values
      end

      private
      def retrieve_pages(titles, rvprops, resolve_redirects = true)
        parms = {'action' => 'query',
                 'prop'   => 'revisions',
                 'rvprop' => Array(rvprops).join('|'),
                 'titles' => Array(titles).join('|'),
                }

        # MediaWiki checks for the presence of the +redirects+ key and ignores the value altogether
        parms['redirects'] = nil if resolve_redirects

        api_request(parms).first.find_first('/m:api/m:query')
      end

      # Normalization is always included in the response
      def normalization(query, title)
        query.find_first("m:normalized/m:n[@to='#{title}']")
      end

      # Resolution of redirects is only included in the response if requested
      def redirection(query, title)
        query.find_first("m:redirects/m:r[@to='#{title}']")
      end

      def validate!(xml)
        raise Error::PageInvalid.new(xml['title'])  if xml['invalid']
      end

    end

    attr_accessor :id, :title, :namespace, :content, :last_modified, :normalized_from, :redirected_from

    def initialize(title)
      @title = title
    end

    #
    # Uses MediaWiki's parse method to return rendered HTML
    #
    def to_html
      CGI.unescapeHTML(Riki::Base.api_request({'action' => 'parse', 'page' => @title}).first.find('/m:api/m:parse/m:text/text()').first.to_s)
    end

    #
    # Returns plain text
    #
    def to_s
      @content
    end
  end
end
