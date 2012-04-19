require 'rest_client'
require 'xml'
require 'active_support'

module Riki
  class Base
    class << self
      attr_accessor :username, :password, :domain, :url
      attr_writer :cache

      def url
        @url ||= 'http://en.wikipedia.org/w/api.php'
      end

      HEADERS = {'User-Agent' => "Riki/v#{Riki::VERSION}"}

      DEFAULT_OPTIONS = {:limit => 500,
                         :maxlag => 5,
                         :retry_count => 3,
                         :retry_delay => 10}

      def cache
        @cache ||= ActiveSupport::Cache::NullStore.new
      end

      def find_by_id(ids)
        expects_array = ids.first.kind_of?(Array)
        return ids.first if expects_array && ids.first.empty?

        ids = ids.flatten.compact.uniq

        case ids.size
          when 0
            raise NotFoundError, "Couldn't find #{name} without an ID"
          when 1
           result = find_one(ids.first)
           expects_array ? [ result ] : result
         else
           find_some(ids)
        end
      end

      #
      # Login to MediaWiki
      #
      def login
        raise "No authentication information provided" if Riki::Base.username.nil? || Riki::Base.password.nil?
        api_request({'action' => 'login', 'lgname' => Riki::Base.username, 'lgpassword' => Riki::Base.password, 'lgdomain' => Riki::Base.domain})
      end

      # Generic API request to API
      #
      # [form_data] hash or string of attributes to post
      # [continue_xpath] XPath selector for query continue parameter
      # [retry_count] Counter for retries
      #
      # Returns XML document
      def api_request(form_data, continue_xpath = nil, retry_count = 1, p_options = {})
        if (!cookies.blank? && cookies["#{cookieprefix}_session"])
          # Attempt to re-use cookies
        else
          # there is no session, we are not currently trying to login, and we gave sufficient auth information
          login if form_data['action'] != 'login' && !Riki::Base.username.blank? && !Riki::Base.password.blank?
        end

        options = DEFAULT_OPTIONS.merge(p_options)

        if form_data.kind_of? Hash
          form_data['format'] = 'xml'
          form_data['maxlag'] = options[:maxlag]
          form_data['includexmlnamespace'] = 'true'
        end

        RestClient.post(Riki::Base.url, form_data, HEADERS.merge({:cookies => cookies})) do |response, &block|
          if response.code == 503 and retry_count < options[:retry_count]
            log.warn("503 Service Unavailable: #{response.body}.  Retry in #{options[:retry_delay]} seconds.")
            sleep(options[:retry_delay])
            api_request(form_data, continue_xpath, retry_count + 1)
          end

          # Check response for errors and return XML
          raise Riki::Error::HttpError.new(response.code) unless response.code >= 200 and response.code < 300

          doc = parse_response(response.dup)

          if(form_data['action'] == 'login')
            login_result = doc.find_first('m:login')['result']
            Riki::Base.cookieprefix = doc.find_first('m:login')['cookieprefix']

            @cookies.merge!(response.cookies)
            case login_result
              when "Success"   then Riki::Base.cache.write(cache_key(:cookies), @cookies)
              when "NeedToken" then api_request(form_data.merge('lgtoken' => doc.find('/m:api/m:login').first['token']))
              else raise Riki::Error::Base.lookup(login_result)
            end
          end
          continue = (continue_xpath and doc.find('m:query-continue').empty?) ? doc.find_first(continue_xpath).value : nil

          return [doc, continue]
        end
      end

      def parse_response(res)
        res = res.force_encoding("UTF-8") if res.respond_to?(:force_encoding)
        doc = XML::Parser.string(res).parse.root
        raise "Response does not contain Mediawiki API XML: #{res}" unless ["api", "mediawiki"].include? doc.name
        doc.namespaces.default_prefix = 'm'

        errors = doc.find('/api/error')
        if errors.any?
          code = errors.first["code"]
          info = errors.first["info"]
          raise Riki::Error::Base.lookup(code).new(info)
        end

        if warnings = doc.find('warnings') && warnings
          warning("API warning: #{warnings.map{|e| e.text}.join(", ")}")
        end

        doc
      end

      def cache_key(key)
        "#{Riki::Base.url}##{key}"
      end

      def cookies
        @cookies ||= Riki::Base.cache.fetch(cache_key(:cookies)) do
          {}
        end
      end

      def cookieprefix
        @cookieprefix ||= Riki::Base.cache.read(cache_key(:cookieprefix))
      end

      def cookieprefix=(cp)
        @cookieprefix ||= Riki::Base.cache.write(cache_key(:cookieprefix), cp)
      end
    end
  end
end
