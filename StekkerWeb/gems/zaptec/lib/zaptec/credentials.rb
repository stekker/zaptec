module Zaptec
  class Credentials
    attr_accessor :access_token, :expires_at

    def initialize(access_token, expires_at)
      @access_token = access_token
      @expires_at = expires_at
    end

    def expired?(at = Time.zone.now)
      expires_at.nil? || at >= expires_at
    end
  end
end
