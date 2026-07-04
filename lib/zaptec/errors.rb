module Zaptec
  module Errors
    class Base < StandardError; end
    class ParameterMissing < Base; end
    class Forbidden < Base; end

    class RequestFailed < Base
      attr_reader :response

      def initialize(message, response = nil)
        @response = response
        super(format_message(message, response))
      end

      private

      def format_message(message, response)
        body = extract_body(response)
        body.present? ? "#{message}: #{body}" : message
      end

      def extract_body(response)
        case response
        when nil then nil
        when Hash then response[:body]
        else response.respond_to?(:body) ? response.body : nil
        end
      end
    end

    class AuthorizationFailed < Base; end
  end
end
