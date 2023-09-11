module Zaptec
  class Client
    BASE_URL = "https://api.zaptec.com".freeze
    USER_ROLE = 1
    OWNER_ROLE = 2
    TOKENS_CACHE_KEY = "zaptec.auth.tokens".freeze

    attr_reader :credentials

    delegate :expired?,
             :access_token,
             :expires_at,
             to: :credentials,
             prefix: true

    def initialize(
      username:,
      password:,
      token_cache: ActiveSupport::Cache::MemoryStore.new,
      encryptor: NullEncryptor.new
    )
      @username = username
      @password = password
      @token_cache = token_cache
      @encryptor = encryptor
    end

    # https://zendesk.zaptec.com/hc/en-001/articles/6062673456657-Access-to-Installations-Authentication-for-Third-Parties#lookup-key-0-0
    def grant_access_url(lookup_key:, partner_name:, redirect_url: nil, language: "en")
      query = URI.encode_www_form(partnerName: partner_name, returnUrl: redirect_url, lang: language)
      "https://portal.zaptec.com/#!/access/request/#{lookup_key}?#{query}"
    end

    # https://zaptec.com/downloads/ZapChargerPro_Integration.pdf
    def authorize(username:, password:)
      raise Errors::ParameterMissing if username.blank? || password.blank?

      start = Time.current

      response = connection.post(
        "#{BASE_URL}/oauth/token",
        {
          username:,
          password:,
          grant_type: "password",
        }.to_query,
        {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      )

      @credentials = Zaptec::Credentials.new(
        response.body["access_token"],
        start + response.body["expires_in"].to_f,
      )
    rescue Faraday::BadRequestError
      raise Errors::AuthorizationFailed
    end

    # https://api.zaptec.com/help/index.html#/Charger/get_api_chargers
    def chargers
      get("/api/chargers", { Roles: USER_ROLE | OWNER_ROLE })
        .body
        .fetch("Data")
        .map { |data| Charger.new(data) }
    end

    # https://api.zaptec.com/help/index.html#/Installation/get_api_installation__id_
    def get_installation(installation_id)
      get("/api/installation/#{installation_id}")
        .then { |response| Installation.new(response.body) }
    end

    # https://api.zaptec.com/help/index.html#/Installation/get_api_installation__id__hierarchy
    def get_installation_hierarchy(installation_id)
      get("/api/installation/#{installation_id}/hierarchy")
        .then { |response| InstallationHierarchy.new(response.body) }
    end

    # https://api.zaptec.com/help/index.html#/Charger/get_api_chargers__id__state
    def state(charger_id, device_type)
      get("/api/chargers/#{charger_id}/state")
        .body
        .to_h do |state|
          [
            Constants.observation_state_id_to_name(state_id: state.fetch("StateId"), device_type:),
            state.fetch("ValueAsString", nil),
          ]
        end
        .then { |data| State.new(data) }
    end

    def pause_charging(charger_id) = send_command(charger_id, :StopChargingFinal)

    def resume_charging(charger_id) = send_command(charger_id, :ResumeCharging)

    private

    attr_reader :username, :password

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end

    def authenticated_connection
      connection.tap do |conn|
        conn.request :authorization, "Bearer", access_token
      end
    end

    # https://api.zaptec.com/help/index.html#/Charger/post_api_chargers__id__sendCommand__commandId_
    def send_command(charger_id, command)
      command_id = Constants.command_to_command_id(command)

      post("/api/chargers/#{charger_id}/sendCommand/#{command_id}")
    end

    def get(endpoint, query = {})
      with_error_handling do
        authenticated_connection.get("#{BASE_URL}#{endpoint}", query)
      end
    end

    def post(endpoint, body: nil, query: nil)
      with_error_handling do
        authenticated_connection.post("#{BASE_URL}#{endpoint}", body) do |req|
          req.params = query unless query.nil?
        end
      end
    end

    def with_error_handling
      token_refreshed ||= false

      yield
    rescue Faraday::UnauthorizedError => e
      if token_refreshed
        raise Errors::RequestFailed.new("Request returned status #{e.response_status}", e.response)
      else
        refresh_access_token!
        token_refreshed = true

        retry
      end
    rescue Faraday::Error => e
      raise Errors::RequestFailed.new("Request returned status #{e.response_status}", e.response)
    end

    def access_token
      current_access_token
        .then do |current|
          if current.expired?
            refresh_access_token!
            current_access_token
          else
            current
          end
        end
        .then(&:access_token)
    end

    def current_access_token
      encrypted_tokens = @token_cache.fetch(TOKENS_CACHE_KEY) do
        @encryptor.encrypt(request_access_token.to_json, cipher_options: { deterministic: true })
      end

      plain_text_tokens = @encryptor.decrypt(encrypted_tokens)
      Credentials.parse(JSON.parse(plain_text_tokens))
    end

    def refresh_access_token!
      @token_cache.write(
        TOKENS_CACHE_KEY,
        @encryptor.encrypt(request_access_token.to_json, cipher_options: { deterministic: true }),
        expires_in: 1.day,
      )
    rescue Faraday::Error => e
      raise Errors::RequestFailed.new("Request returned status #{e.response_status}", e.response)
    end

    # https://developer.easee.cloud/reference/post_api-accounts-login
    def request_access_token = authorize(username:, password:)
  end
end
