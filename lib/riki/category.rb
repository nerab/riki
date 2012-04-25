module Riki
  #
  # Represents a MediaWiki category. Category members could be pages, categories and files.
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

      # Grouping by type allows coarse-grained API calls.
      @members.group_by{|cm| cm['type']}.each do |type, members|
        result.concat(TypeRegistry.get(type).find_by_title(members.map{|cm| cm['title']}))
      end

      result
    end
  end
end
