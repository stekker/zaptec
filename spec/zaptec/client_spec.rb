RSpec.describe Zaptec::Client do
  describe "authentication" do
    it "obtains and uses a new access token when none is provided" do
      Timecop.freeze(Time.zone.now.change(usec: 0))

      WebMock::API
        .stub_request(:post, "https://api.zaptec.com/oauth/token")
        .with(
          body: { grant_type: "password", username: "zap", password: "tec" },
          headers: { "Content-Type": "application/x-www-form-urlencoded" }
        )
        .to_return(
          body: {
            access_token: "T123",
            token_type: "Bearer",
            expires_in: 1.hour.to_i
          }.to_json
        )

      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/chargers?Roles=3")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(body: { Data: [] }.to_json)

      tokens = { "access_token" => "T123", "expires_at" => 1.hour.from_now.to_i }
      token_cache = ActiveSupport::Cache::MemoryStore.new
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      expect { client.chargers }
        .to change { token_cache.fetch(Zaptec::Client::TOKENS_CACHE_KEY) }
        .from(nil)
        .to(tokens.to_json)
    end

    it "re-authorizes when it is expired" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      current_tokens = { "access_token" => "T123", "expires_at" => 2.minutes.ago.to_i }
      token_cache.write(Zaptec::Client::TOKENS_CACHE_KEY, current_tokens.to_json)
      new_tokens = { "access_token" => "T789", "expires_at" => 1.hour.from_now.to_i }

      WebMock::API
        .stub_request(:post, "https://api.zaptec.com/oauth/token")
        .with(
          body: { grant_type: "password", username: "zap", password: "tec" },
          headers: { "Content-Type": "application/x-www-form-urlencoded" }
        )
        .to_return(
          body: {
            access_token: "T789",
            token_type: "Bearer",
            expires_in: 1.hour.to_i
          }.to_json
        )

      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/chargers?Roles=3")
        .with(headers: { "Authorization" => "Bearer T789" })
        .to_return(body: { Data: [] }.to_json)

      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      expect { client.chargers }
        .to change { token_cache.fetch(Zaptec::Client::TOKENS_CACHE_KEY) }
        .from(current_tokens.to_json)
        .to(new_tokens.to_json)
    end

    it "uses the encryptor to encrypt the tokens" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      tokens = { "access_token" => "T123", "expires_at" => 1.hour.from_now.to_i }

      encryptor = instance_double(Zaptec::NullEncryptor)
      allow(encryptor).to receive(:encrypt).and_return("encrypted")
      allow(encryptor).to receive(:decrypt).and_return(tokens.to_json)

      WebMock::API
        .stub_request(:post, "https://api.zaptec.com/oauth/token")
        .with(
          body: { grant_type: "password", username: "zap", password: "tec" },
          headers: { "Content-Type": "application/x-www-form-urlencoded" }
        )
        .to_return(
          body: {
            access_token: "T123",
            token_type: "Bearer",
            expires_in: 1.hour.to_i
          }.to_json
        )

      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/chargers?Roles=3")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(body: { Data: [] }.to_json)

      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:, encryptor:)

      expect { client.chargers }
        .to change { token_cache.fetch(Zaptec::Client::TOKENS_CACHE_KEY) }
        .from(nil)
        .to("encrypted")

      expect(encryptor).to have_received(:encrypt).with(tokens.to_json, cipher_options: { deterministic: true })
      expect(encryptor).to have_received(:decrypt).with("encrypted")
    end
  end

  describe "#authorize" do
    it "receives a token upon authorization" do
      WebMock::API
        .stub_request(:post, "https://api.zaptec.com/oauth/token")
        .with(
          body: { grant_type: "password", password: "12345", username: "stekker@example.com" },
          headers: { "Content-Type": "application/x-www-form-urlencoded" }
        )
        .to_return(
          body: {
            access_token: "abc",
            token_type: "Bearer",
            expires_in: 86_399
          }.to_json
        )

      Timecop.freeze

      token_cache = ActiveSupport::Cache::MemoryStore.new
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      credentials = client.authorize(username: "stekker@example.com", password: "12345")

      expect(credentials.access_token).to eq "abc"
      expect(credentials.expires_at).to eq Time.zone.now + 86_399
    end

    it "raises an AuthorizationFailed error on a 400 response" do
      WebMock::API
        .stub_request(:post, "https://api.zaptec.com/oauth/token")
        .with(
          body: { grant_type: "password", password: "12345", username: "stekker@example.com" },
          headers: { "Content-Type": "application/x-www-form-urlencoded" }
        )
        .to_return(status: 400)

      token_cache = ActiveSupport::Cache::MemoryStore.new
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      expect { client.authorize(username: "stekker@example.com", password: "12345") }
        .to raise_error(Zaptec::Errors::AuthorizationFailed)
    end
  end

  describe "#chargers" do
    it "gets the list of chargers" do
      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/chargers?Roles=3")
        .to_return(body: chargers_example.to_json)

      token_cache = build_token_cache("T123")
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      expect(client.chargers).to be_one

      expect(client.chargers.first)
        .to have_attributes(
          id: "de522271-91f5-45b8-916b-07e258ff07d2",
          name: "Zaptec",
          device_id: "ZAP049387",
          device_type: 4,
          installation_name: "Antonio Morohof 1",
          installation_id: "b30adfd3-3442-432e-88ea-8782b7e69b2f"
        )
    end
  end

  describe "#state" do
    it "can fetch the state for a charger" do
      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/chargers/123/state")
        .to_return(body: charger_state_example.to_json)

      token_cache = build_token_cache("T123")
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)
      device_type_apollo = 4

      expect(client.state("123", device_type_apollo))
        .to have_attributes(
          total_charge_power: 2.83012,
          max_phases: 3,
          total_charge_power_session: 1.42012,
          charging?: false,
          online?: true,
          disconnected?: true
        )
    end

    it "includes a meter reading" do
      Timecop.freeze

      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/chargers/123/state")
        .to_return(body: charger_state_example.to_json)

      token_cache = build_token_cache("T123")
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)
      device_type_apollo = 4
      state = client.state("123", device_type_apollo)

      expect(state.meter_reading)
        .to have_attributes(
          reading_kwh: 2.83012,
          timestamp: Time.zone.now
        )
    end
  end

  it "does not raise an error for unknown states" do
    WebMock::API
      .stub_request(:get, "https://api.zaptec.com/api/chargers/123/state")
      .to_return(
        body: [
          {
            ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
            StateId: 99999,
            Timestamp: "2022-12-05T13:10:10.837",
            ValueAsString: "1"
          }
        ].to_json
      )

    token_cache = build_token_cache("T123")
    client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)
    device_type_apollo = 4

    expect { client.state("123", device_type_apollo) }.not_to raise_error
  end

  {
    pause_charging: 506,
    resume_charging: 507
  }.each do |operation, command_id|
    describe "##{operation}" do
      # rubocop:disable RSpec/NoExpectationExample
      it "posts a #{operation} command" do
        WebMock::API
          .stub_request(:post, "https://api.zaptec.com/api/chargers/123/sendCommand/#{command_id}")
          .to_return(status: 200)

        token_cache = build_token_cache("T123")
        client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

        client.public_send(operation.to_sym, "123")
      end
      # rubocop:enable RSpec/NoExpectationExample

      it "raises a RequestFailed error when the request fails" do
        WebMock::API
          .stub_request(:post, "https://api.zaptec.com/api/chargers/123/sendCommand/#{command_id}")
          .to_return(status: 500)

        token_cache = build_token_cache("T123")
        client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

        expect { client.public_send(operation.to_sym, "123") }
          .to raise_error(Zaptec::Errors::RequestFailed, "Request returned status 500")
      end
    end
  end

  describe "#get_installation_hierarchy" do
    it "fetches the hierarchy for an installation" do
      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/installation/I123/hierarchy")
        .to_return(
          body: <<~JSON
            {
              "Id": "b30adfd3-3442-432e-88ea-8782b7e69b2f",
              "Name": "Stekker test",
              "InstallationName": "Stekker test",
              "NetworkType": 4,
              "Circuits": [
                {
                  "Id": "8043ea1d-31ce-4a20-a953-2ea5721f9d44",
                  "Name": "Charge circuit",
                  "MaxCurrent": 10,
                  "IsActive": true,
                  "Active": true,
                  "InstallationId": "b30adfd3-3442-432e-88ea-8782b7e69b2f",
                  "InstallationName": "Stekker test",
                  "Chargers": [
                    {
                      "Id": "de522271-91f5-45b8-916b-07e258ff07d2",
                      "DeviceId": "ZAP049387",
                      "MID": "ZAP049387",
                      "Name": "Zaptec",
                      "SerialNo": "Zaptec",
                      "Active": true,
                      "DeviceType": 4
                    }
                  ]
                }
              ]
            }
          JSON
        )

      token_cache = build_token_cache("T123")
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      installation_hierarchy = client.get_installation_hierarchy("I123")
      circuit = installation_hierarchy.circuits.first
      charger = circuit.chargers.first

      expect(installation_hierarchy)
        .to have_attributes(
          id: "b30adfd3-3442-432e-88ea-8782b7e69b2f",
          name: "Stekker test",
          network_type: "TN_3_Phase"
        )

      expect(circuit)
        .to have_attributes(
          id: "8043ea1d-31ce-4a20-a953-2ea5721f9d44",
          max_current: 10
        )

      expect(charger)
        .to have_attributes(
          id: "de522271-91f5-45b8-916b-07e258ff07d2",
          name: "Zaptec"
        )
    end
  end

  describe "#get_installation" do
    it "fetches installation information" do
      WebMock::API
        .stub_request(:get, "https://api.zaptec.com/api/installation/I123")
        .to_return(
          body: <<~JSON
            {
              "Id": "1234abcd-12df-4979-sr97-3a69432e8d2c",
              "Name": "Home",
              "Address": "Lindelaan 31",
              "ZipCode": "1234 Ab",
              "City": "Laderburg",
              "CountryId": "bda681ab-adcb-4f67-bac5-5cbf28d42cc7",
              "InstallationType": 0,
              "MaxCurrent": 123.0,
              "AvailableCurrentMode": 0,
              "AvailableCurrentScheduleWeekendActive": false,
              "InstallationCategoryId": "5c624162-e595-4167-a8bb-8b33a1487b62",
              "InstallationCategory": "Community_Installation_Category",
              "UseLoadBalancing": true,
              "IsRequiredAuthentication": true,
              "Latitude": 51.949433,
              "Longitude": 5.231064,
              "Notes": "Circuit C",
              "Active": true,
              "NetworkType": 4,
              "AvailableInternetAccessPLC": true,
              "AvailableInternetAccessWiFi": false,
              "CreatedOnDate": "2017-08-16T09:34:29.78",
              "UpdatedOn": "2023-03-24T11:00:01.35",
              "CurrentUserRoles": 70,
              "AuthenticationType": 0,
              "MessagingEnabled": false,
              "RoutingId": "default",
              "OcppCloudUrlVersion": 0,
              "TimeZoneName": "(UTC+00:00) United Kingdom Time",
              "TimeZoneIanaName": "Europe/London",
              "IsSubscriptionsAvailableForCurrentUser": false,
              "AvailableFeatures": 183,
              "EnabledFeatures": 0,
              "ActiveChargerCount": 21,
              "Feature_PowerManagement_EcoMode_DepartureTime": 360,
              "Feature_PowerManagement_EcoMode_MinEnergy": 10.0,
              "Feature_PowerManagement_Apm_SinglePhaseMappedToPhase": 1,
              "PropertyIsMinimumPowerOfflineMode": false,
              "PropertyOfflineModeAllowAnonymous": false,
              "PropertyExperimentalFeaturesEnabled": 0,
              "PropertyEnergySensorRippleEnabled": false,
              "PropertyEnergySensorRippleNumBits": 1,
              "PropertyEnergySensorRipplePercentBits01": 30,
              "PropertyEnergySensorRipplePercentBits10": 60,
              "PropertyFirmwareAutomaticUpdates": true,
              "PropertySessionMaxStopCount": 0
            }
          JSON
        )

      token_cache = build_token_cache("T123")
      client = Zaptec::Client.new(username: "zap", password: "tec", token_cache:)

      installation = client.get_installation("I123")

      expect(installation)
        .to have_attributes(
          address: "Lindelaan 31",
          zip_code: "1234 Ab",
          city: "Laderburg",
          country_code: "NLD",
          latitude: 51.949433,
          longitude: 5.231064
        )
    end
  end

  private

  def chargers_example
    {
      Pages: 1,
      Data: [
        {
          OperatingMode: 1,
          IsOnline: true,
          Id: "de522271-91f5-45b8-916b-07e258ff07d2",
          MID: "ZAP049387",
          DeviceId: "ZAP049387",
          SerialNo: "Zaptec",
          Name: "Zaptec",
          CreatedOnDate: "2022-09-16T08:06:10.487",
          CircuitId: "8043ea1d-31ce-4a20-a953-2ea5721f9d44",
          Active: true,
          CurrentUserRoles: 3,
          Pin: "4912",
          DeviceType: 4,
          InstallationName: "Antonio Morohof 1",
          InstallationId: "b30adfd3-3442-432e-88ea-8782b7e69b2f",
          AuthenticationType: 2,
          IsAuthorizationRequired: true
        }
      ]
    }
  end

  def charger_state_example
    [
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: -3,
        Timestamp: "2022-12-05T13:10:10.837",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: -2,
        Timestamp: "2022-12-01T00:40:19.487",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: -1,
        Timestamp: "2022-12-05T15:29:21.713"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 1,
        Timestamp: "2022-09-16T08:11:01.797",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 120,
        Timestamp: "2022-09-16T13:09:19.38",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 145,
        Timestamp: "2022-09-16T08:08:16.06",
        ValueAsString: "3600"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 147,
        Timestamp: "2022-09-28T13:47:52.52",
        ValueAsString: "600"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 150,
        Timestamp: "2022-09-16T12:40:34.537",
        ValueAsString: "LTE"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 151,
        Timestamp: "2022-09-16T08:08:16.057",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 153,
        Timestamp: "2022-09-16T08:08:16.18",
        ValueAsString: "0.700"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 201,
        Timestamp: "2022-12-05T12:56:14.447",
        ValueAsString: "22.399"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 202,
        Timestamp: "2022-09-17T11:59:13.493",
        ValueAsString: "31.231"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 204,
        Timestamp: "2022-09-17T11:59:13.493",
        ValueAsString: "31.568"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 205,
        Timestamp: "2022-09-17T11:59:13.493",
        ValueAsString: "31.652"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 206,
        Timestamp: "2022-09-17T11:59:13.497",
        ValueAsString: "28.311"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 207,
        Timestamp: "2022-09-17T11:59:13.497",
        ValueAsString: "30.352"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 270,
        Timestamp: "2022-12-05T12:56:14.447",
        ValueAsString: "31.923"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 501,
        Timestamp: "2022-12-01T00:39:23.78",
        ValueAsString: "1.257"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 502,
        Timestamp: "2022-12-01T00:39:23.783",
        ValueAsString: "3.196"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 503,
        Timestamp: "2022-12-01T00:39:23.783",
        ValueAsString: "1.089"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 507,
        Timestamp: "2022-11-30T22:46:54.887",
        ValueAsString: "0.022"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 508,
        Timestamp: "2022-09-28T13:43:03",
        ValueAsString: "0.023"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 509,
        Timestamp: "2022-12-01T00:39:23.78",
        ValueAsString: "0.022"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 510,
        Timestamp: "2022-09-16T08:06:11.157",
        ValueAsString: "10.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 511,
        Timestamp: "2022-09-16T08:00:57.967",
        ValueAsString: "6.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 513,
        Timestamp: "2022-09-28T13:42:37.577",
        ValueAsString: "2.83012"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 519,
        Timestamp: "2022-10-01T16:59:15.767",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 520,
        Timestamp: "2022-09-16T08:00:57.967",
        ValueAsString: "3"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 522,
        Timestamp: "2022-09-16T09:01:26.483",
        ValueAsString: "4"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 523,
        Timestamp: "2022-09-16T08:00:57.97",
        ValueAsString: "10.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 544,
        Timestamp: "2022-09-16T08:08:16.063",
        ValueAsString: "2"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 545,
        Timestamp: "2022-09-16T08:00:52.687",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 546,
        Timestamp: "2022-09-16T08:05:21.137",
        ValueAsString: "10.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 547,
        Timestamp: "2022-09-16T08:05:21.137",
        ValueAsString: "10.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 548,
        Timestamp: "2022-09-16T08:00:57.423",
        ValueAsString: "4"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 553,
        Timestamp: "2022-10-07T18:53:10.193",
        ValueAsString: "1.42012"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 554,
        Timestamp: "2022-09-28T14:00:01.31",
        ValueAsString: "OCMF|#{
          {
            "FV" => "1.0",
            "GI" => "ZAPTEC GO",
            "GS" => "ZAP049387",
            "GV" => "1.1.0.5",
            "PG" => "F1",
            "RD" => [
              {
                "TM" => "2022-09-28T14:00:00,000+00:00 R",
                "RV" => 24.368,
                "RI" => "1-0:1.8.0",
                "RU" => "kWh",
                "RT" => "AC",
                "ST" => "G"
              }
            ]
          }.to_json
        }"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 702,
        Timestamp: "2022-10-05T08:28:37.36",
        ValueAsString: "12"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 708,
        Timestamp: "2022-10-05T08:28:28.33",
        ValueAsString: "0.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 710,
        Timestamp: "2022-10-05T08:28:17.433",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 711,
        Timestamp: "2022-09-16T08:06:11.16",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 712,
        Timestamp: "2022-09-16T08:06:12.187",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 714,
        Timestamp: "2022-10-16T12:21:50.493",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 715,
        Timestamp: "2022-09-16T08:00:52.687",
        ValueAsString: "4"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 718,
        Timestamp: "2022-09-16T11:04:27.243",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 721,
        Timestamp: "2022-10-07T18:53:13.037",
        ValueAsString: ""
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 722,
        Timestamp: "2022-10-05T08:28:17.433"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 723,
        Timestamp: "2022-09-28T13:47:52.513",
        ValueAsString: {
          "SessionId" => "d262f8a5-a470-447d-bb81-b88df14ba0e2",
          "Energy" => 0,
          "StartDateTime" => "2022-09-28T13:47:39.217128Z",
          "EndDateTime" => "2022-09-28T13:47:51.629294Z",
          "ReliableClock" => true,
          "StoppedByRFID" => false,
          "AuthenticationCode" => "nfc-04D97A628E6784",
          "SignedSession" =>
            "OCMF|#{
              {
                "FV" => "1.0",
                "GI" => "ZAPTEC GO",
                "GS" => "ZAP049387",
                "GV" => "1.1.0.5",
                "PG" => "T1",
                "RD" => [
                  {
                    "TM" => "2022-09-28T13:47:39,000+00:00 R",
                    "TX" => "B",
                    "RV" => 24.368,
                    "RI" => "1-0:1.8.0",
                    "RU" => "kWh",
                    "RT" => "AC",
                    "ST" => "G"
                  },
                  {
                    "TM" => "2022-09-28T13:47:51,000+00:00 R",
                    "TX" => "E",
                    "RV" => 24.368,
                    "RI" => "1-0:1.8.0",
                    "RU" => "kWh",
                    "RT" => "AC",
                    "ST" => "G"
                  }
                ]
              }.to_json
            }"
        }.to_json
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 733,
        Timestamp: "2022-09-16T08:11:01.797",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 749,
        Timestamp: "2022-09-16T09:02:35.513",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 751,
        Timestamp: "2022-09-16T12:57:05.99",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 760,
        Timestamp: "2022-09-16T08:11:42.957",
        ValueAsString: "NLD"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 761,
        Timestamp: "2022-09-16T08:11:43.973",
        ValueAsString: "Europe/Amsterdam"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 800,
        Timestamp: "2022-09-16T08:06:11.16",
        ValueAsString: "b30adfd3-3442-432e-88ea-8782b7e69b2f"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 801,
        Timestamp: "2022-09-16T08:00:57.97",
        ValueAsString: "default"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 802,
        Timestamp: "2022-09-16T08:06:11.16",
        ValueAsString: "Zaptec"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 804,
        Timestamp: "2022-09-16T08:06:10.637",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 805,
        Timestamp: "2022-09-16T08:06:11.163",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 807,
        Timestamp: "2022-12-01T00:39:23.813",
        ValueAsString: "#2 mqttUncon:3900 disc:4195 noc:4195 op:1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 808,
        Timestamp: "2022-12-05T12:56:14.45",
        ValueAsString: "4d 12h15m07s T_EM: 14.01 13.67 13.54  T_M: 13.16 13.70   V: 1.21 3.14 1.07   " \
                       "I: 0.02 0.02 0.02  C12 CM1 MCnt:4297384 Rs:0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 809,
        Timestamp: "2022-12-01T00:39:23.58",
        ValueAsString: "60.000"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 811,
        Timestamp: "2022-10-07T18:53:13.04",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 815,
        Timestamp: "2022-09-16T12:40:34.39",
        ValueAsString: "3"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 823,
        Timestamp: "2022-09-16T08:08:16.06",
        ValueAsString: "8"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 908,
        Timestamp: "2022-09-16T08:11:01.837",
        ValueAsString: "1.0.0.6"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 909,
        Timestamp: "2022-09-16T12:40:34.39",
        ValueAsString: "0"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 911,
        Timestamp: "2022-09-16T08:11:01.833",
        ValueAsString: "1.1.0.5"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 916,
        Timestamp: "2022-09-16T08:11:01.837",
        ValueAsString: "1.1.0.5"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 917,
        Timestamp: "2022-09-16T08:11:01.837",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 918,
        Timestamp: "2022-09-16T08:11:01.84",
        ValueAsString: "1"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 952,
        Timestamp: "2022-09-16T08:08:16.097",
        ValueAsString: "40:91:51:2e:2b:40"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 960,
        Timestamp: "2022-09-16T12:40:33.423",
        ValueAsString: "242016001458383"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 962,
        Timestamp: "2022-09-16T12:40:33.427",
        ValueAsString: "89470060210810145491"
      },
      {
        ChargerId: "de522271-91f5-45b8-916b-07e258ff07d2",
        StateId: 963,
        Timestamp: "2022-09-16T12:40:33.427",
        ValueAsString: "862020054465567"
      }
    ]
  end

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

  def build_zaptec_charger
    Zaptec::Charger.new(
      id: "123",
      name: "Zaptec",
      device_id: "ZAP049387",
      device_type: 4,
      installation_name: "Antonio Morohof 1",
      installation_id: "b30adfd3-3442-432e-88ea-8782b7e69b2f"
    )
  end

  def build_token_cache(access_token, expires_at: 1.hour.from_now)
    ActiveSupport::Cache::MemoryStore.new.tap do |token_cache|
      token_cache.write(
        Zaptec::Client::TOKENS_CACHE_KEY,
        Zaptec::Credentials.new(access_token, expires_at).to_json
      )
    end
  end
end
