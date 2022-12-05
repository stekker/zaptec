module Zaptec
  class Charger
    attr_reader :id,
                :name,
                :device_id,
                :installation_name,
                :installation_id

    def initialize(
      id:,
      name:,
      device_id:,
      installation_name:,
      installation_id:
    )

      @id = id
      @name = name
      @device_id = device_id
      @installation_name = installation_name
      @installation_id = installation_id
    end

    def self.parse(data)
      new(
        id: data.fetch("Id"),
        name: data.fetch("Name"),
        device_id: data.fetch("DeviceId"),
        installation_name: data.fetch("InstallationName"),
        installation_id: data.fetch("InstallationId")
      )
    end
  end
end
