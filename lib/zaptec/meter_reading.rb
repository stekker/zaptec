module Zaptec
  class MeterReading
    GOOD = "G".freeze
    KWH = "kWh".freeze
    READINGS = "RD".freeze
    STATUS = "ST".freeze
    TIMESTAMP = "TM".freeze
    UNIT = "RU".freeze
    VALUE = "RV".freeze
    WH = "Wh".freeze

    # https://github.com/SAFE-eV/OCMF-Open-Charge-Metering-Format/blob/master/OCMF-de.md#json-basiertes-ocmf-format
    attr_reader :reading_kwh, :timestamp

    def initialize(reading_kwh:, timestamp:)
      @reading_kwh = reading_kwh
      @timestamp = timestamp
    end

    class << self
      def parse(ocmf_meter_reading)
        _prefix, json_payload, _signature = ocmf_meter_reading.split("|")

        data = JSON.parse(json_payload)

        meter_reading = data.fetch(READINGS).detect do |reading|
          reading.fetch(STATUS) == GOOD && reading[UNIT].in?([WH, KWH])
        end

        return if meter_reading.blank?

        timestamp = Time.zone.parse(meter_reading.fetch(TIMESTAMP).split.first)

        kwh_magnitude =
          case meter_reading.fetch(UNIT)
          when KWH then 1
          when WH then 1000.0
          end

        reading_kwh = meter_reading.fetch(VALUE) / kwh_magnitude

        new(reading_kwh:, timestamp:)
      end
    end
  end
end
