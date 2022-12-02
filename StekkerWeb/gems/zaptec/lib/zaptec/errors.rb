module Zaptec
  module Errors
    class BaseError < StandardError; end
    class ParameterMissingError < BaseError; end
    class UnauthorizedError < BaseError; end
  end
end
