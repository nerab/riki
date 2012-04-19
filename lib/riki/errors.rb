module Riki
  module Error
    # = Riki Errors
    #
    # Generic Riki exception class.
    class Base < StandardError
      class << self
        def lookup(code)
          # TODO Search all submodules
          code = code.to_sym
          Login.const_defined?(code) ? Login.const_get(code) : nil || Base
        end
      end
    end

    class HttpError < Base
      def initialize(code)
        super("API returned HTTP status code #{code}")
      end
    end

    # Raised when an object cannot be found with the query parameters supplied
    class NotFound < Base #:nodoc:
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

    #
    # The names of the classes in this module are equal to the API response
    #
    # <api><login result="NotExists" /></api> is mapped to Riki::Error::Login::NotExists
    #
    module Login
      class Illegal < Base #:nodoc:
        def initialize
          super('Illegal username')
        end
      end

      class NotExists < Base #:nodoc:
        def initialize
          super("The username you provided doesn't exist in the given authentication domain")
        end
      end

      class EmptyPass < Base #:nodoc:
        def initialize
          super('No or empty password provided')
        end
      end

      class WrongPass < Base #:nodoc:
        def initialize
          super('The provided password is incorrect for the given user name and authentication domain')
        end
      end

      class WrongPluginPass < WrongPass #:nodoc:
        def initialize
          super('The provided password is incorrect (rejected by authentication plugin)')
        end
      end

      class Throttled < Base #:nodoc:
        def initialize
          super('Logged in too many times in a short time')
        end
      end

      class Blocked < Base #:nodoc:
        def initialize
          super('User is blocked')
        end
      end
    end
  end
end
