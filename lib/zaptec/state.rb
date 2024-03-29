module Zaptec
  class State
    CONNECTED_REQUESTING = "Connected_Requesting".freeze
    CONNECTED_CHARGING = "Connected_Charging".freeze
    DISCONNECTED = "Disconnected".freeze
    CHARGING_MODES = [CONNECTED_CHARGING, CONNECTED_REQUESTING].freeze

    def initialize(data)
      @data = data
    end

    def total_charge_power = @data.fetch(:TotalChargePower).to_f

    def max_phases = @data.fetch(:MaxPhases).to_i

    def total_charge_power_session = @data.fetch(:TotalChargePowerSession).to_f

    def charging? = charger_operation_mode.in?(CHARGING_MODES)

    def disconnected? = charger_operation_mode == DISCONNECTED

    def online? = @data.fetch(:IsOnline).to_i.positive?

    def meter_reading
      @meter_reading ||= MeterReading.parse(@data.fetch(:SignedMeterValue))
    end

    private

    def charger_operation_mode
      Constants.charger_operation_mode_to_name(@data.fetch(:ChargerOperationMode).to_i)
    end
  end
end
