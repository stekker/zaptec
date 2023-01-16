module Zaptec
  class Client
    BASE_URI = "https://api.zaptec.com".freeze
    USER_ROLE = 1
    OWNER_ROLE = 2

    attr_reader :http_client, :credentials

    delegate :expired?,
             :access_token,
             :expires_at,
             to: :credentials,
             prefix: true

    def initialize(credentials: nil)
      @credentials = credentials

      @http_client = Faraday.new(url: BASE_URI) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end

    # https://zaptec.com/downloads/ZapChargerPro_Integration.pdf
    def authorize(username:, password:)
      raise Errors::ParameterMissing if username.blank? || password.blank?

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
    rescue Faraday::BadRequestError
      raise Errors::AuthorizationFailed
    end

    # https://api.zaptec.com/help/index.html#/Charger/get_api_chargers
    def chargers
      get("/api/chargers", { Roles: USER_ROLE | OWNER_ROLE })
        .body
        .fetch("Data")
        .map { |data| Charger.parse(data) }
    end

    # https://api.zaptec.com/help/index.html#/Charger/get_api_chargers__id__state
    def state(charger_id, device_type)
      get("/api/chargers/#{charger_id}/state")
        .body
        .to_h do |state|
          [
            Constants.observation_state_id_to_name(state_id: state.fetch("StateId"), device_type: device_type),
            state.fetch("ValueAsString", nil)
          ]
        end
        .then { |data| State.new(data) }
    end

    def pause_charging(charger_id) = send_command(charger_id, :StopChargingFinal)

    def resume_charging(charger_id) = send_command(charger_id, :ResumeCharging)

    private

    # https://api.zaptec.com/help/index.html#/Charger/post_api_chargers__id__sendCommand__commandId_
    def send_command(charger_id, command)
      command_id = Constants.command_to_command_id(command)

      post("/api/chargers/#{charger_id}/sendCommand/#{command_id}")
    end

    def get(endpoint, query = {})
      require_valid_credentials!

      http_client.get(
        "#{BASE_URI}#{endpoint}",
        query,
        { Authorization: "Bearer #{credentials.access_token}" }
      )
    end

    def post(endpoint, body = nil)
      require_valid_credentials!

      http_client.post(
        "#{BASE_URI}#{endpoint}",
        body,
        { Authorization: "Bearer #{credentials.access_token}" }
      )
    rescue Faraday::Error => e
      raise Errors::RequestFailed, "Request returned status #{e.response_status}"
    end

    def require_valid_credentials!
      raise Errors::Unauthorized if credentials.blank? || credentials.expired?
    end
  end
end
