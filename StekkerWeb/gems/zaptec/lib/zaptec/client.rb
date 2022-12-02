module Zaptec
  class Client
    ZAPTEC_API = "https://api.zaptec.com".freeze

    attr_reader :http_client, :credentials

    def initialize(credentials: nil)
      @credentials = credentials

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

    # https://api.zaptec.com/help/index.html#/Installation/get_api_installation
    def installations
      raise Errors::UnauthorizedError unless credentials&.expired? == false

      user_role = 1
      owner_role = 2

      response = http_client.get(
        "#{ZAPTEC_API}/api/installation",
        {
          Roles: user_role + owner_role
        },
        {
          "accept" => "text/plain",
          "Authorization" => "Bearer #{credentials.access_token}"
        }
      )

      response.body
    end
  end
end
