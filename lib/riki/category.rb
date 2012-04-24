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
          cat.members = retrieve_categories(title).find('m:categorymembers/m:cm')
          result << cat
        end

        result
      end

      private

      def retrieve_categories(title)
        parms = {'action'  => 'query',
                 'list'    => 'categorymembers',
                 'cmtitle' => title["Category:"] ? title : "Category:#{title}",
                 'cmprop'  => ['title', 'type', 'timestamp'].join('|'),
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
      result = []

      @members.group_by{|cm| cm['type']}.each do |type, members|
        result.concat(class_for(type).find_by_title(members.map{|cm| cm['title']}))
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
  end
end
