require 'cgi'
require 'date'

module Riki
  #
  # Represents a MediaWiki page. Only the latest revision of a page is considered.
  #
  class Page < Base
    class << self
      def find_by_title(titles)
        titles = [titles] unless titles.kind_of?(Array) # always treat titles as array
        return [] if titles.empty?

        results = {}
        redirects = []

        # find cached pages
        titles.each{|title|
          cached = Riki::Base.cache.read(cache_key("page_#{title}"))
          if cached
            results[title] = cached
            Riki.logger.info "Found cached version of page '#{title}'"
          end
        }
        
        # TODO Handle Redirect and Normalized objects
        
        # Check _in one coarse-grained API call which cached pages are still current
        if results.any?
          api_request({'action' => 'query', 'prop' => 'revisions', 'rvprop' => 'timestamp', 'titles' => results.keys.join('|'), 'redirects' => nil}).first.find('/m:api/m:query/m:pages/m:page').each{|page|
            last_modified = DateTime.strptime(page.find_first('m:revisions/m:rev')['timestamp'], '%Y-%m-%dT%H:%M:%S%Z')
            title = page['title']

            normalized = page.find_first('../../m:normalized/m:n')
            if normalized
              Riki.logger.info "Requested page '#{title}' is probably cached under its normalized title '#{normalized['to']}'"
              
              # check cache again
              cached = Riki::Base.cache.read(cache_key("page_#{normalized['to']}"))
              if cached
                results[normalized['to']] = cached
                titles.delete(title)
                Riki.logger.info "Found cached version of normalized page '#{normalized['to']}'"
              end
            end
            
            # TODO redirects
            
            
            # TODO Make sure we delete redirects and normalizations that are stale
            if results[title] && last_modified < results[title].last_modified
              Riki.logger.info "Cached version of page '#{title}' is from #{results[title].last_modified}, but an updated version is available that dates #{last_modified}" 
              titles.delete(title)
            end
          }
        end

        Riki.logger.info "Currency check leaves these pages to retrieve in full: #{titles.join(', ')}"
        
        return results.values if titles.empty? # no titles asked for or all results cached and current

        api_request({'action' => 'query', 'prop' => 'revisions', 'rvprop' => 'content|timestamp', 'titles' => titles.join('|'), 'redirects' => nil}).first.find('/m:api/m:query/m:pages/m:page').each{|page|
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
          Riki.logger.info "Page '#{p.title}' was written to the cache" 

          # Cache the non-normalized form so that the next query will hit the cache even if asking for the non-normalized version
          # <normalized><n from="ISO_639-2" to="ISO 639-2" /></normalized>
          normalized = page.find_first('../../m:normalized/m:n')
          if normalized
            Riki.logger.info "Caching non-normalized title '#{normalized['from']}' for page '#{p.title}'"
            Riki::Base.cache.write(cache_key("page_#{normalized['from']}"), Normalized.new(normalized['from'], normalized['to'])) 
          end
          
          # Cache the page under the title of the redirect source
          # <redirects><r from="&quot;Mimia&quot;" to="Mimipiscis" tofragment=""/>
          redirected = page.find_first('../../m:redirects/m:r')
          if redirected
            Riki.logger.info "Caching redirect source '#{redirected['from']}' for page '#{p.title}'"
            Riki::Base.cache.write(cache_key("page_#{redirected['from']}"), Redirect.new(redirected['from'], redirected['to'])) 
          end
          
          results[p.title] = p
        }

        results.values
      end

      private

      def validate!(xml)
        raise Error::PageInvalid.new(xml['title'])  if xml['invalid']
      end

    end

    attr_accessor :id, :title, :namespace, :content, :last_modified

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
