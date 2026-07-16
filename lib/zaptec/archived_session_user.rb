module Zaptec
  class ArchivedSessionUser
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:id)
    def email = @data[:email]
    def full_name = @data[:fullName]
  end
end
