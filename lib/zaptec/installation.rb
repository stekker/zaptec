module Zaptec
  class Installation
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:Id)
    def address = @data[:Address]
    def zip_code = @data[:ZipCode]
    def city = @data[:City]
    def latitude = @data[:Latitude]
    def country_code = Constants.country_id_to_country_code(@data[:CountryId])
    def longitude = @data[:Longitude]
  end
end
