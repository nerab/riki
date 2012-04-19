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
          results[title] = cached if cached
        }

        # Check _in one coarse-grained API call which cached pages are still current
        if results.any?
          api_request({'action' => 'query', 'prop' => 'revisions', 'rvprop' => 'timestamp', 'titles' => results.keys.join('|'), 'redirects' => nil}).first.find('/m:api/m:query/m:pages/m:page').each{|page|
            last_modified = DateTime.strptime(page.find_first('m:revisions/m:rev')['timestamp'], '%Y-%m-%dT%H:%M:%S%Z')
            title = page['title']

            if !results[title]
              normalized = page.find_first('../../m:normalized/m:n')
              if normalized
                titles.delete(title)
                title = normalized['from']
              end
            end

            # TODO Redirect isn't properly working yet
            if !results[title]
              redirect = page.find_first('../../m:redirect/m:r')
              if redirect
                titles.delete(title)
                title = redirect['from']
              end
            end

            # TODO Make sure we delete redirects and normalizations that are stale
            titles.delete(title) if results[title] && last_modified <= results[title].last_modified
          }
        end

        return results.values if titles.empty? # no titles asked for or all results cached and current

        api_request({'action' => 'query', 'prop' => 'revisions', 'rvprop' => 'content|timestamp', 'titles' => titles.join('|')}).first.find('/m:api/m:query/m:pages/m:page').each{|page|
          validate!(page)
          p = Page.new(page['title'])

          p.id = page['pageid'].to_i
          p.namespace = page['ns']

          rev = page.find_first('m:revisions/m:rev')
          p.content = rev.content
          p.last_modified = DateTime.strptime(rev['timestamp'], '%Y-%m-%dT%H:%M:%S%Z')

          Riki::Base.cache.write(cache_key("page_#{p.title}"), p)

          # Also cache the non-normalized form so that the next query will hit the cache even if asking for the non-normalized version
          # <normalized><n from="ISO_639-2" to="ISO 639-2" /></normalized>
          normalized = page.find_first('../../m:normalized/m:n')
          Riki::Base.cache.write(cache_key("page_#{normalized['from']}"), p) if normalized

          # Cache the page under the title of the redirect source
          # <redirects><r from="AJAX Proxy" to="HTTP Proxy for AJAX Applications" tofragment=""/>
          redirected = page.find_first('../../m:redirect/m:r')
          Riki::Base.cache.write(cache_key("page_#{redirected['from']}"), p) if redirected

          results[p.title] = p
        }

        results.values
      end

      private

      def validate!(xml)
        raise Error::PageNotFound.new(xml['title']) if xml['missing']
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
