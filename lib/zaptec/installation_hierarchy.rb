module Zaptec
  class InstallationHierarchy
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:Id)
    def name = @data.fetch(:Name)
    def network_type = Constants.network_type_to_name(@data.fetch(:NetworkType))

    def circuits
      @circuits ||= @data.fetch(:Circuits).map { |data| Circuit.new(data) }
    end
  end
end
