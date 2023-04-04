module Zaptec
  class Installation
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:Id)

    def circuits
      @circuits ||= @data.fetch(:Circuits).map { |data| Circuit.new(data) }
    end
  end
end
