module Zaptec
  class Client
    BASE_URI = "https://api.zaptec.com".freeze
    USER_ROLE = 1
    OWNER_ROLE = 2

    # https://api.zaptec.com/api/constants
    OBSERVATIONS = {
      "Unknown": 0,
      "OfflineMode": 1,
      "AuthenticationRequired": 120,
      "PaymentActive": 130,
      "PaymentCurrency": 131,
      "PaymentSessionUnitPrice": 132,
      "PaymentEnergyUnitPrice": 133,
      "PaymentTimeUnitPrice": 134,
      "CommunicationMode": 150,
      "PermanentCableLock": 151,
      "ProductCode": 152,
      "HmiBrightness": 153,
      "LockCableWhenConnected": 154,
      "SoftStartDisabled": 155,
      "FirmwareApiHost": 156,
      "MIDBlinkEnabled": 170,
      "ProductionTesterEnabled": 180,
      "ProductionTestStationOverride": 181,
      "TemperatureInternal5": 201,
      "TemperatureInternal6": 202,
      "TemperatureInternalLimit": 203,
      "TemperatureInternalMaxLimit": 241,
      "Humidity": 270,
      "VoltagePhase1": 501,
      "VoltagePhase2": 502,
      "VoltagePhase3": 503,
      "CurrentPhase1": 507,
      "CurrentPhase2": 508,
      "CurrentPhase3": 509,
      "ChargerMaxCurrent": 510,
      "ChargerMinCurrent": 511,
      "ActivePhases": 512,
      "TotalChargePower": 513,
      "RcdCurrent": 515,
      "Internal12vCurrent": 517,
      "PowerFactor": 518,
      "SetPhases": 519,
      "MaxPhases": 520,
      "ChargerOfflinePhase": 522,
      "ChargerOfflineCurrent": 523,
      "RcdCalibration": 540,
      "RcdCalibrationNoise": 541,
      "TotalChargePowerSession": 553,
      "SignedMeterValue": 554,
      "SignedMeterValueInterval": 555,
      "SessionEnergyCountExportActive": 560,
      "SessionEnergyCountExportReactive": 561,
      "SessionEnergyCountImportActive": 562,
      "SessionEnergyCountImportReactive": 563,
      "SoftStartTime": 570,
      "ChargeDuration": 701,
      "ChargeMode": 702,
      "ChargePilotLevelInstant": 703,
      "ChargePilotLevelAverage": 704,
      "PilotVsProximityTime": 706,
      "ChargeCurrentInstallationMaxLimit": 707,
      "ChargeCurrentSet": 708,
      "ChargerOperationMode": 710,
      "IsEnabled": 711,
      "IsStandAlone": 712,
      "ChargerCurrentUserUuidDeprecated": 713,
      "CableType": 714,
      "NetworkType": 715,
      "DetectedCar": 716,
      "GridTestResult": 717,
      "FinalStopActive": 718,
      "SessionIdentifier": 721,
      "ChargerCurrentUserUuid": 722,
      "CompletedSession": 723,
      "NewChargeCard": 750,
      "AuthenticationListVersion": 751,
      "EnabledNfcTechnologies": 752,
      "LteRoamingDisabled": 753,
      "Location": 760,
      "TimeZone": 761,
      "TimeSchedule": 762,
      "NextScheduleEvent": 763,
      "MaxStartDelay": 764,
      "InstallationId": 800,
      "RoutingId": 801,
      "Notifications": 803,
      "Warnings": 804,
      "DiagnosticsMode": 805,
      "InternalDiagnosticsLog": 807,
      "DiagnosticsString": 808,
      "CommunicationSignalStrength": 809,
      "CloudConnectionStatus": 810,
      "McuResetSource": 811,
      "McuRxErrors": 812,
      "McuToVariscitePacketErrors": 813,
      "VarisciteToMcuPacketErrors": 814,
      "UptimeVariscite": 820,
      "UptimeMCU": 821,
      "CarSessionLog": 850,
      "CommunicationModeConfigurationInconsistency": 851,
      "RawPilotMonitor": 852,
      "IT3PhaseDiagnosticsLog": 853,
      "PilotTestResults": 854,
      "UnconditionalNfcDetectionIndication": 855,
      "EmcTestCounter": 899,
      "ProductionTestResults": 900,
      "PostProductionTestResults": 901,
      "SmartMainboardSoftwareApplicationVersion": 908,
      "SmartMainboardSoftwareBootloaderVersion": 909,
      "SmartComputerSoftwareApplicationVersion": 911,
      "SmartComputerSoftwareBootloaderVersion": 912,
      "SmartComputerHardwareVersion": 913,
      "MacMain": 950,
      "MacPlcModuleGrid": 951,
      "MacWiFi": 952,
      "MacPlcModuleEv": 953,
      "LteImsi": 960,
      "LteMsisdn": 961,
      "LteIccid": 962,
      "LteImei": 963,
      "ProductionTestStationNumber": 970,
      "MIDCalibration": 980,
      "IsOcppConnected": -3,
      "IsOnline": -2,
      "Pulse": -1
    }.freeze

    attr_reader :http_client, :credentials

    def initialize(credentials: nil)
      @credentials = credentials

      @http_client = Faraday.new(url: BASE_URI) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end

    def authorize(username:, password:)
      raise Errors::ParameterMissingError if username.blank? || password.blank?

      start = Time.zone.now

      response = http_client.post(
        "#{BASE_URI}/oauth/token",
        {
          username: username,
          password: password,
          grant_type: "password"
        }.to_query,
        {
          "Content-Type": "application/x-www-form-urlencoded"
        }
      )

      @credentials = Zaptec::Credentials.new(
        response.body["access_token"],
        start + response.body["expires_in"].to_f
      )
    end

    # https://api.zaptec.com/help/index.html#/Charger/get_api_chargers
    def chargers
      raise Errors::UnauthorizedError if credentials.expired?

      get("/api/chargers", { Roles: USER_ROLE | OWNER_ROLE })
        .body
        .fetch("Data")
        .map { |data| Charger.parse(data) }
    end

    # https://api.zaptec.com/help/index.html#/Installation/get_api_installation
    def installations
      raise Errors::UnauthorizedError if credentials.expired?

      get("/api/installation", { Roles: USER_ROLE | OWNER_ROLE }).body
    end

    def state(charger)
      get("/api/chargers/#{charger.id}/state")
        .body
        .to_h do |state|
          observation_name =
            OBSERVATIONS
              .detect { |_observation_name, observation_id| observation_id == state.fetch("StateId") }
              .then { |observation_name, _observation_id| observation_name }

          [observation_name, state.fetch("ValueAsString", nil)]
        end
    end

    private

    def get(endpoint, query = {})
      raise Errors::UnauthorizedError if credentials.expired?

      http_client.get(
        "#{BASE_URI}#{endpoint}",
        query,
        { Authorization: "Bearer #{credentials.access_token}" }
      )
    end
  end
end
