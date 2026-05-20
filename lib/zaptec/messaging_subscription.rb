require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"

module Zaptec
  class MessagingSubscription
    Message = Data.define(:device_id, :device_type, :state_id, :state_name, :timestamp, :value, :raw)

    TOKEN_TTL = 1.hour
    TOKEN_REFRESH_MARGIN = 5.minutes

    def initialize(connection_details:)
      @connection_details = connection_details
    end

    def each_message(mode: :consume, timeout: 30)
      return enum_for(:each_message, mode:, timeout:) unless block_given?

      loop do
        message = fetch_one(mode:, timeout:)
        yield message if message
      end
    end

    private

    attr_reader :connection_details

    def fetch_one(mode:, timeout:)
      response = http.request(message_request(mode:, timeout:))

      case response
      when Net::HTTPNoContent
        nil
      when Net::HTTPSuccess
        parse_message(response.body.to_s)
      when Net::HTTPUnauthorized
        invalidate_token!
        raise Errors::AuthorizationFailed
      else
        raise Errors::RequestFailed.new("#{response.code} #{response.message}: #{response.body}", response)
      end
    end

    def message_request(mode:, timeout:)
      klass = mode == :peek ? Net::HTTP::Post : Net::HTTP::Delete
      klass.new(message_path(timeout)).tap do |req|
        req["Authorization"] = sas_token
        req["Content-Length"] = "0"
      end
    end

    def message_path(timeout)
      "/#{connection_details.topic}/subscriptions/#{connection_details.subscription}" \
        "/messages/head?timeout=#{timeout}"
    end

    def parse_message(body)
      start_index = body.index("{")
      end_index = body.rindex("}")
      return nil unless start_index && end_index && end_index > start_index

      raw = JSON.parse(body[start_index..end_index])
      state_id = raw["StateId"]
      device_type = raw["DeviceType"]

      Message.new(
        device_id: raw["DeviceId"],
        device_type:,
        state_id:,
        state_name: state_name_for(state_id, device_type),
        timestamp: raw["Timestamp"],
        value: raw["ValueAsString"],
        raw:,
      )
    rescue JSON::ParserError
      nil
    end

    def state_name_for(state_id, device_type)
      return unless state_id && device_type

      Constants.observation_state_id_to_name(state_id:, device_type:)
    end

    def sas_token
      now = Time.now.to_i
      if @token.nil? || now > @token_expiry - TOKEN_REFRESH_MARGIN.to_i
        @token_expiry = now + TOKEN_TTL.to_i
        @token = build_sas_token(expiry: @token_expiry)
      end
      @token
    end

    def build_sas_token(expiry:)
      encoded_uri = URI.encode_www_form_component("https://#{connection_details.host}/")
      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest("sha256", connection_details.password, "#{encoded_uri}\n#{expiry}"),
      )

      "SharedAccessSignature " \
        "sr=#{encoded_uri}" \
        "&sig=#{URI.encode_www_form_component(signature)}" \
        "&se=#{expiry}" \
        "&skn=#{connection_details.username}"
    end

    def invalidate_token!
      @token = nil
      @token_expiry = nil
    end

    def http
      @http ||=
        Net::HTTP.new(connection_details.host, 443).tap do |conn|
          conn.use_ssl = true
          conn.read_timeout = 90
        end
    end
  end
end
