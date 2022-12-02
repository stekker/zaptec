module Zaptec
  class Client
    ZAPTEC_API = "https://api.zaptec.com".freeze

    attr_reader :http_client, :credentials

    def initialize
      @http_client = Faraday.new(@base_url) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end

    def authorize(username:, password:)
      raise Errors::ParameterMissingError if username.blank? || password.blank?

      start = Time.zone.now

      response = http_client.post(
        "#{ZAPTEC_API}/oauth/token",
        {
          username: username,
          password: password,
          grant_type: "password"
        }.to_query,
        {
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      )

      @credentials = Zaptec::Credentials.new(
        response.body["access_token"],
        start + response.body["expires_in"].to_f
      )
    end
  end
end
