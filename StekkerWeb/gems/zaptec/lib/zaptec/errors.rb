module Zaptec
  module Errors
    class Base < StandardError; end
    class ParameterMissing < Base; end
    class Unauthorized < Base; end
  end
end
