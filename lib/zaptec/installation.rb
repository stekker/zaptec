module Zaptec
  class Installation
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def address = @data.fetch(:Address)
    def zip_code = @data.fetch(:ZipCode)
    def city = @data.fetch(:City)
    def latitude = @data.fetch(:Latitude)
    def country_code = Constants.country_id_to_country_code(@data.fetch(:CountryId))
    def longitude = @data.fetch(:Longitude)
  end
end
