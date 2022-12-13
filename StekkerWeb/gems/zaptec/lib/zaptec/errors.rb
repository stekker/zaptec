module Zaptec
  module Errors
    class Base < StandardError; end
    class ParameterMissing < Base; end
    class Unauthorized < Base; end
    class RequestFailed < Base; end
    class AuthorizationFailed < Base; end
  end
end
