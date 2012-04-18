module Riki
  # = Riki Errors
  #
  # Generic Riki exception class.
  class RikiError < StandardError
    class << self
      def lookup(code)
        ERRORS[code.to_sym] || RikiError
      end
    end
  end

  # Raised when the authorization information was present, but was not sufficient to complete the request
  class Unauthorized < RikiError #:nodoc:
  end

  # Raised when an object cannot be found with the query parameters supplied
  class NotFound < RikiError #:nodoc:
    attr_reader :title

    def initialize(message, title)
      super(message)
      @title = title
    end
  end

  # Raised when a page that was searched for could not be found
  class PageNotFound < NotFound #:nodoc:
    def initialize(title)
      super("Could not find a page named '#{title}'", title)
    end
  end

  # Raised when a page that was searched for is not a valid
  class PageInvalid < NotFound #:nodoc:
    def initialize(title)
      super("The page title '#{title}' is not valid", title)
    end
  end

  class RikiError < StandardError
    ERRORS = {
      :readapidenied => Unauthorized
    }
  end
end
