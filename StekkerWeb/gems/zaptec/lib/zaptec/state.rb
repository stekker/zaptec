module Zaptec
  class State
    def initialize(data)
      @data = data
    end

    def total_charge_power = @data.fetch(:TotalChargePower).to_f

    def max_phases = @data.fetch(:MaxPhases).to_i

    def total_charge_power_session = @data.fetch(:TotalChargePowerSession).to_f
  end
end
