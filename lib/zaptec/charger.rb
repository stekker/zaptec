module Zaptec
  class Charger
    NONE_ROLE = 0
    USER_ROLE = 1
    OWNER_ROLE = 2
    MAINTAINER_ROLE = 4
    ADMINISTRATOR_ROLE = 8
    TECHNICAL_ROLE = 128

    ROLES = {
      user: USER_ROLE,
      owner: OWNER_ROLE,
      maintainer: MAINTAINER_ROLE,
      administrator: ADMINISTRATOR_ROLE,
      technical: TECHNICAL_ROLE,
    }.freeze

    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:Id)
    def name = @data.fetch(:Name)
    def device_id = @data.fetch(:DeviceId)
    def device_type = @data.fetch(:DeviceType)
    def installation_name = @data.fetch(:InstallationName)
    def installation_id = @data.fetch(:InstallationId)

    def active? = @data.fetch(:Active, false)

    def current_user_roles = @data.fetch(:CurrentUserRoles, NONE_ROLE)

    def user? = role?(USER_ROLE)
    def owner? = role?(OWNER_ROLE)
    def maintainer? = role?(MAINTAINER_ROLE)
    def administrator? = role?(ADMINISTRATOR_ROLE)
    def technical? = role?(TECHNICAL_ROLE)

    def role_names = ROLES.select { |_name, bit| role?(bit) }.keys

    def service_level_technical_read_access?
      @data.fetch(:CurrentUserHasServiceLevelTechnicalReadAccess, false)
    end

    private

    def role?(bit) = current_user_roles.to_i.anybits?(bit)
  end
end
