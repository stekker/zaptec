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
    end

    # https://api.zaptec.com/help/index.html#/Charger/get_api_chargers
    def chargers
      raise Errors::Unauthorized if credentials.expired?

      get("/api/chargers", { Roles: USER_ROLE | OWNER_ROLE })
        .body
        .fetch("Data")
        .map { |data| Charger.parse(data) }
    end

    # https://api.zaptec.com/help/index.html#/Installation/get_api_installation
    def installations
      raise Errors::Unauthorized if credentials.expired?

      get("/api/installation", { Roles: USER_ROLE | OWNER_ROLE }).body
    end

    def state(charger_id, device_type)
      get("/api/chargers/#{charger_id}/state")
        .body
        .to_h do |state|
          [
            self.class.device_type_observation_ids(device_type).fetch(state.fetch("StateId")),
            state.fetch("ValueAsString", nil)
          ]
        end
        .then { |data| State.new(data) }
    end

    def start_charging(charger_id) = send_command(charger_id, :StartCharging)

    def pause_charging(charger_id) = send_command(charger_id, :StopCharging)

    def finish_charging(charger_id) = send_command(charger_id, :StopChargingFinal)

    private

    def send_command(charger_id, command)
      command_id =
        self
          .class
          .constants
          .fetch("Commands")
          .fetch(command.to_s) { raise "Unknown command '#{command}'" }

      post("/api/chargers/#{charger_id}/sendCommand/#{command_id}")
    end

    def get(endpoint, query = {})
      raise Errors::Unauthorized if credentials.expired?

      http_client.get(
        "#{BASE_URI}#{endpoint}",
        query,
        { Authorization: "Bearer #{credentials.access_token}" }
      )
    end

    def post(endpoint, body = nil)
      raise Errors::Unauthorized if credentials.expired?

      http_client.post(
        "#{BASE_URI}#{endpoint}",
        body,
        { Authorization: "Bearer #{credentials.access_token}" }
      )
    rescue Faraday::Error => e
      raise Errors::RequestFailed, "Request returned status #{e.response_status}"
    end

    class << self
      def device_type_observation_ids(device_type)
        @device_type_observation_ids ||= {}

        @device_type_observation_ids[device_type] ||=
          begin
            global_observation_ids = constants.fetch("Observations").invert.transform_values(&:to_sym)

            device_specific_observations =
              constants
                .fetch("Schema")
                .fetch(device_type_to_name(device_type))
                .fetch("ObservationIds")
                .invert
                .transform_values(&:to_sym)

            global_observation_ids.merge(device_specific_observations)
          end
      end

      def device_type_to_name(device_type)
        constants
          .fetch("DeviceTypes")
          .detect { |_name, type| type == device_type }
          .then { |name, _type| name }
      end

      def constants_file = Pathname.new(__dir__).join("../../data/constants.json")

      def constants
        @constants ||= JSON.parse(constants_file.read)
      end
    end
  end
end
