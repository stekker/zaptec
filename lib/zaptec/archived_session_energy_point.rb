module Zaptec
  class ArchivedSessionEnergyPoint
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def timestamp = Time.zone.parse(@data.fetch(:timestamp))
    def energy_kwh = @data[:energy]
  end
end
