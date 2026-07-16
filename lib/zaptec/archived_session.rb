module Zaptec
  class ArchivedSession
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:id)
    def external_id = @data[:externalId]
    def replaced_by_session_id = @data[:replacedBySessionId]
    def token_name = @data[:tokenName]
    def charger_id = @data[:chargerId]
    def device_id = @data[:deviceId]
    def device_name = @data[:deviceName]
    def charger_firmware_version = @data[:chargerFirmwareVersion]
    def energy_kwh = @data[:energy]
    def session_signature = @data[:sessionSignature]
    def session_signature_eichrecht = @data[:sessionSignatureEichreicht]

    def start_date_time = parse_time(:startDateTime)
    def end_date_time = parse_time(:endDateTime)
    def recognized_date_time = parse_time(:recognizedDateTime)

    def offline? = @data.fetch(:offline, false)
    def reliable_clock? = @data.fetch(:reliableClock, false)
    def stopped_by_rfid? = @data.fetch(:stoppedByRfid, false)
    def signed? = @data.fetch(:signed, false)
    def voided? = @data.fetch(:voided, false)
    def aborted? = @data.fetch(:aborted, false)
    def ocpp_native? = @data.fetch(:ocppNative, false)
    def externally_abandoned? = @data.fetch(:externallyAbandoned, false)

    def authorized_user
      @authorized_user ||= @data[:authorizedUser].then do |user|
        user.nil? ? nil : ArchivedSessionUser.new(user)
      end
    end

    def energy_details
      @energy_details ||= (@data[:energyDetails] || []).map { |point| ArchivedSessionEnergyPoint.new(point) }
    end

    def meter_readings
      @meter_readings ||= MeterReading.parse_all(session_signature)
    end

    private

    def parse_time(key)
      value = @data[key]
      return if value.nil?

      Time.zone.parse(value)
    end
  end
end
