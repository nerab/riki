module Riki
  #
  # Represents a MediaWiki page. Only the latest revision of a page is considered.
  #
  class Category < Base
    class << self
      def find_by_title(titles)
        # MediaWiki can't retrieve multiple categories at once, at least as of API version 1.1.
        # In order to keep our API consistent, we simulate this behavior by looping over all given categories.
        result = []
        Array(titles).each do |title|
          cat = Category.new(title)

          # Group results by type so we can call the finders coarse-grained
          retrieve_categories(title).find('m:categorymembers/m:cm').group_by{|cm| cm['type']}.each do |type, members|
            # TODO Store proxies instead of full-fledged objects in order to keep them lighweight
            cat.members.concat(members.map{|cm| cm['title']})
          end
          
          result << cat          
        end
        
        result
      end

      private
      
      CLASS_MAP = {
        'subcat' => Category
      }
      
      def class_for(type)
        CLASS_MAP[type] || Riki.const_get(type.classify)
      end
      
      def retrieve_categories(title)        
        parms = {'action'  => 'query',
                 'list'    => 'categorymembers',
                 'cmtitle' => title["Category:"] ? title : "Category:#{title}",
                 'cmprop'  => ['title', 'type'].join('|'),
                 'cmlimit' => 100,
                }
        api_request(parms).first.find_first('/m:api/m:query')
      end
    end

    attr_accessor :title
    attr_writer :members

    def initialize(title)
      @title = title
      @members = []
    end

    def members
      # TODO Resolve category and page proxies
      @members
    end
  end
end
