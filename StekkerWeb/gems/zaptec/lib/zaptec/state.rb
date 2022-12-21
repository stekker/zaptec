module Zaptec
  class State
    CHARGING_MODES = %w[Connected_Requesting Connected_Charging].freeze

    def initialize(data)
      @data = data
    end

    def total_charge_power = @data.fetch(:TotalChargePower).to_f

    def max_phases = @data.fetch(:MaxPhases).to_i

    def total_charge_power_session = @data.fetch(:TotalChargePowerSession).to_f

    def charging? = charger_operation_mode.in?(CHARGING_MODES)

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
