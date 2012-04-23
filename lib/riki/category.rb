module Riki
  #
  # Represents a MediaWiki page. Only the latest revision of a page is considered.
  #
  class Category < Base
    class << self
      def find_by_title(title)
        result = Category.new(title)
        category_members = retrieve_categories(title).find('m:categorymembers/m:cm/@title')
        result.members = Page.find_by_title(category_members.map{|x| x.value})

        return result
      end

      private
      def retrieve_categories(title)
        parms = {'action'  => 'query',
                 'list'    => 'categorymembers',
                 'cmtitle' => "Category:#{title}",
                 'cmlimit' => 100,
                }
        api_request(parms).first.find_first('/m:api/m:query')
      end
    end

    attr_accessor :title, :members

    def initialize(title)
      @title = title
      @members = []
    end

  end
end
