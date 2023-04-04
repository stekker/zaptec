module Zaptec
  class Circuit
    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:Id)

    def chargers
      @chargers ||= @data.fetch(:Chargers).map { |data| Charger.new(data) }
    end
  end
end
