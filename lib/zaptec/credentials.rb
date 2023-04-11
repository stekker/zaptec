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

    def self.parse(data)
      new(
        data.fetch("access_token"),
        Time.zone.at(data.fetch("expires_at"))
      )
    end

    def as_json(*)
      super.merge("expires_at" => expires_at.to_i)
    end
  end
end
