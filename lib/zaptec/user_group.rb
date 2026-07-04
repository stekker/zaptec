module Zaptec
  class UserGroup
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:Id) { @data.fetch(:id) }
    def name = @data[:Name] || @data[:name]
  end
end
