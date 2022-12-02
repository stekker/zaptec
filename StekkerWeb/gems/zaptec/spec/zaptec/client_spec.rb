RSpec.describe Zaptec::Client do
  describe "#authorize" do
    it "receives a token upon authorization" do
      WebMock::API.stub_request(:post, "https://api.zaptec.com/oauth/token")
        .to_return(
          body: {
            access_token: "abc",
            token_type: "Bearer",
            expires_in: 86_399
          }.to_json
        )

      Timecop.freeze

      client = described_class.new

      credentials = client.authorize(username: "stekker@example.com", password: "12345")

      expect(credentials.access_token).to eq "abc"
      expect(credentials.expires_at).to eq Time.zone.now + 86_399
    end
  end

  describe "#installations" do
    it "gets the list of chargers for the account" do
      WebMock::API.stub_request(:get, "https://api.zaptec.com/api/installation?Roles=3")
        .to_return(body: installation_example.to_json)

      client = described_class.new(credentials: Zaptec::Credentials.new("abc", 1.hour.from_now))

      chargers = client.installations

      expect(chargers).to eq "abc"
    end
  end

  private

  def installation_example
    {
      "Pages" => 1,
      "Data" => [
        {
          "Id" => "b30adfd3-3442-432e-88ea-8782b7e69b2f",
          "Name" => "Antonio Morohof 1",
          "CountryId" => "bda681ab-adcb-4f67-bac5-5cbf28d42cc7",
          "InstallationType" => 1,
          "MaxCurrent" => 10.0,
          "AvailableCurrentMode" => 0,
          "AvailableCurrentScheduleWeekendActive" => false,
          "InstallationCategoryId" => "d72d6374-7f73-4df5-8056-60635b177421",
          "InstallationCategory" => "Private_Installation_Category",
          "UseLoadBalancing" => true,
          "IsRequiredAuthentication" => true,
          "Latitude" => 0.0,
          "Longitude" => 0.0,
          "Active" => true,
          "NetworkType" => 4,
          "AvailableInternetAccessPLC" => false,
          "AvailableInternetAccessWiFi" => false,
          "CreatedOnDate" => "2022-09-16T08:06:10.217",
          "UpdatedOn" => "2022-12-02T14:03:29.403",
          "CurrentUserRoles" => 3,
          "AuthenticationType" => 2,
          "MessagingEnabled" => true,
          "RoutingId" => "default",
          "OcppCloudUrl" => "ws://ocpp.e-flux.nl/1.6/alvachargingservices/{deviceId}",
          "OcppCloudUrlVersion" => 0,
          "IsSubscriptionsAvailableForCurrentUser" => false,
          "AvailableFeatures" => 471,
          "EnabledFeatures" => 0
        }
      ]
    }
  end
end
