module Zaptec
  class Charger
    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:Id)
    def name = @data.fetch(:Name)
    def device_id = @data.fetch(:DeviceId)
    def device_type = @data.fetch(:DeviceType)
    def installation_name = @data.fetch(:InstallationName)
    def installation_id = @data.fetch(:InstallationId)
  end
end
