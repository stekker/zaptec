module Zaptec
  module Errors
    class Base < StandardError; end
    class ParameterMissing < Base; end
    class Unauthorized < Base; end
    class RequestFailed < Base
      attr_reader :response

      def initialize(message, response = nil)
        @response = response
        super(message)
      end
    end
    class AuthorizationFailed < Base; end
  end
end
