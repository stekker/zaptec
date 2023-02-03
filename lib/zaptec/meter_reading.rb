module Zaptec
  class MeterReading
    attr_reader :reading_kwh, :timestamp

    def initialize(reading_kwh:, timestamp:)
      @reading_kwh = reading_kwh
      @timestamp = timestamp
    end
  end
end
