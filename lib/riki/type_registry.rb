module Riki
  #
  # Maps a MediaWiki type to the corresponding Riki class
  #
  class TypeRegistry
    class << self
      def get(type)
        self.send(type.to_sym)
      end
      
      def subcat
        Category
      end
    
      def method_missing(sym, *args, &block)
        if respond_to?(sym)
          Riki.const_get(sym.to_s.classify)
        else
          super #(sym, *args, &block)
        end
      end
          
      def respond_to?(sym)
        Riki.const_defined?(sym.to_s.classify)
      end
    end
  end
end