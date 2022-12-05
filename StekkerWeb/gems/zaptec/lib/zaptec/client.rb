module Zaptec
  class Client
    BASE_URI = "https://api.zaptec.com".freeze
    USER_ROLE = 1
    OWNER_ROLE = 2

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
        "#{BASE_URI}/oauth/token",
        {
          username: username,
          password: password,
          grant_type: "password"
        }.to_query,
        {
          "Content-Type": "application/x-www-form-urlencoded"
        }
      )

      @credentials = Zaptec::Credentials.new(
        response.body["access_token"],
        start + response.body["expires_in"].to_f
      )
    end

    # https://api.zaptec.com/help/index.html#/Installation/get_api_installation
    def installations
      raise Errors::UnauthorizedError if credentials.expired?

      response = get("/api/installation")

      response.body
    end

    private

    def get(endpoint)
      raise Errors::UnauthorizedError if credentials.expired?

      http_client.get(
        "#{BASE_URI}#{endpoint}",
        query,
        { Authorization: "Bearer #{credentials.access_token}" }
      )
    end
  end
end
