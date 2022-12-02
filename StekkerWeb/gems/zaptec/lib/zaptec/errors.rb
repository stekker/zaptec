module Zaptec
  module Errors
    class BaseError < StandardError; end
    class ParameterMissingError < BaseError; end
  end
end
