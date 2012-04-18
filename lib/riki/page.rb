require 'cgi'
require 'nokogiri'
require 'date'

module Riki
  #
  # Represents a MediaWiki page. Only the latest revision of a page is considered.
  #
  class Page < Base
    class << self
      def find_by_title(titles)
        titles = [titles] unless titles.kind_of?(Array) # always treat titles as array

        results = {}

        # TODO Transform the requested title to its normalized form. Maybe double-cache or alias?
        # <normalized><n from="ISO_639-2" to="ISO 639-2" /></normalized>

        # find cached pages
        titles.each{|title|
          cached = Riki::Base.cache.read(cache_key("page_#{title}"))
          results[title] = cached if cached
        }

        # Check _in one coarse-grained API call which cached pages are still current
        if results.any?
          api_request({'action' => 'query', 'prop' => 'revisions', 'rvprop' => 'timestamp', 'titles' => results.keys.join('|')}).first.find('/m:api/m:query/m:pages/m:page').each{|page|
            last_modified = DateTime.strptime(page.find_first('m:revisions/m:rev')['timestamp'], '%Y-%m-%dT%H:%M:%S%Z')
            title = page['title']
            titles.delete(title) if last_modified <= results[title].last_modified
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

          Riki::Base.cache.write(cache_key("page_#{p.title}"), p, :expires_in => 12.hours)

          results[p.title] = p
        }

        results.values
      end

      private

      def validate!(xml)
        raise PageNotFound.new(xml['title']) if xml['missing']
        raise PageInvalid.new(xml['title'])  if xml['invalid']
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
