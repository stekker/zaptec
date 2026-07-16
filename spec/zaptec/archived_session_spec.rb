RSpec.describe Zaptec::ArchivedSession do
  it "exposes the top-level session fields" do
    session = described_class.new(
      "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "externalId" => "tx-42",
      "chargerId" => "c0000000-0000-0000-0000-000000000001",
      "deviceId" => "ZAP123456",
      "deviceName" => "Zaptec-1",
      "chargerFirmwareVersion" => "3.2.1",
      "startDateTime" => "2026-01-05T10:00:00Z",
      "endDateTime" => "2026-01-05T11:30:00Z",
      "recognizedDateTime" => "2026-01-05T11:30:05Z",
      "energy" => 12.34,
      "tokenName" => "RFID-ABC",
    )

    expect(session).to have_attributes(
      id: "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      external_id: "tx-42",
      charger_id: "c0000000-0000-0000-0000-000000000001",
      device_id: "ZAP123456",
      device_name: "Zaptec-1",
      charger_firmware_version: "3.2.1",
      start_date_time: Time.zone.parse("2026-01-05T10:00:00Z"),
      end_date_time: Time.zone.parse("2026-01-05T11:30:00Z"),
      recognized_date_time: Time.zone.parse("2026-01-05T11:30:05Z"),
      energy_kwh: 12.34,
      token_name: "RFID-ABC",
    )
  end

  it "returns nil for optional timestamps and identifiers when absent" do
    session = described_class.new(
      "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "startDateTime" => "2026-01-05T10:00:00Z",
    )

    expect(session).to have_attributes(
      external_id: nil,
      end_date_time: nil,
      recognized_date_time: nil,
      device_id: nil,
      device_name: nil,
      charger_firmware_version: nil,
      token_name: nil,
      replaced_by_session_id: nil,
      energy_kwh: nil,
    )
  end

  it "exposes the boolean flags" do
    session = described_class.new(
      "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "startDateTime" => "2026-01-05T10:00:00Z",
      "offline" => true,
      "reliableClock" => false,
      "stoppedByRfid" => true,
      "signed" => true,
      "voided" => false,
      "aborted" => false,
      "ocppNative" => true,
      "externallyAbandoned" => false,
    )

    expect(session).to be_offline
    expect(session).not_to be_reliable_clock
    expect(session).to be_stopped_by_rfid
    expect(session).to be_signed
    expect(session).not_to be_voided
    expect(session).not_to be_aborted
    expect(session).to be_ocpp_native
    expect(session).not_to be_externally_abandoned
  end

  it "defaults the boolean flags to false when the API omits them" do
    session = described_class.new(
      "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "startDateTime" => "2026-01-05T10:00:00Z",
    )

    expect(session).not_to be_offline
    expect(session).not_to be_reliable_clock
    expect(session).not_to be_stopped_by_rfid
    expect(session).not_to be_signed
    expect(session).not_to be_voided
    expect(session).not_to be_aborted
    expect(session).not_to be_ocpp_native
    expect(session).not_to be_externally_abandoned
  end

  it "exposes the replaced-by session id when the session was voided" do
    session = described_class.new(
      "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "startDateTime" => "2026-01-05T10:00:00Z",
      "voided" => true,
      "replacedBySessionId" => "b1e5a5f0-1111-4c8b-9d2f-000000000099",
    )

    expect(session).to be_voided
    expect(session.replaced_by_session_id).to eq "b1e5a5f0-1111-4c8b-9d2f-000000000099"
  end

  it "exposes the OCMF payloads when present" do
    session = described_class.new(
      "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "startDateTime" => "2026-01-05T10:00:00Z",
      "sessionSignature" => "OCMF|{...}|sig",
      "sessionSignatureEichreicht" => "OCMF|{...}|sig-eichrecht",
    )

    expect(session.session_signature).to eq "OCMF|{...}|sig"
    expect(session.session_signature_eichrecht).to eq "OCMF|{...}|sig-eichrecht"
  end

  describe "#authorized_user" do
    it "parses the authorized user when present" do
      session = described_class.new(
        "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
        "startDateTime" => "2026-01-05T10:00:00Z",
        "authorizedUser" => {
          "id" => "u0000000-0000-0000-0000-000000000001",
          "email" => "driver@example.com",
          "fullName" => "Anne Driver",
        },
      )

      expect(session.authorized_user)
        .to have_attributes(
          id: "u0000000-0000-0000-0000-000000000001",
          email: "driver@example.com",
          full_name: "Anne Driver",
        )
    end

    it "is nil when the authorized user is absent" do
      session = described_class.new(
        "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
        "startDateTime" => "2026-01-05T10:00:00Z",
      )

      expect(session.authorized_user).to be_nil
    end
  end

  describe "#meter_readings" do
    it "parses the OCMF sessionSignature into cumulative meter readings" do
      session = described_class.new(
        "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
        "startDateTime" => "2026-01-05T10:00:00Z",
        "sessionSignature" =>
          'OCMF|{"FV":"1.0","RD":[' \
          '{"TM":"2026-01-05T10:00:00,000+00:00 R","TX":"B","RV":100.0,"RU":"kWh","ST":"G"},' \
          '{"TM":"2026-01-05T11:00:00,000+00:00 R","TX":"T","RV":103.5,"RU":"kWh","ST":"G"},' \
          '{"TM":"2026-01-05T12:00:00,000+00:00 R","TX":"E","RV":110.2,"RU":"kWh","ST":"G"}' \
          ']}|{"SD":"abc"}',
      )

      expect(session.meter_readings).to match(
        [
          have_attributes(timestamp: Time.zone.parse("2026-01-05T10:00:00Z"), reading_kwh: 100.0),
          have_attributes(timestamp: Time.zone.parse("2026-01-05T11:00:00Z"), reading_kwh: 103.5),
          have_attributes(timestamp: Time.zone.parse("2026-01-05T12:00:00Z"), reading_kwh: 110.2),
        ],
      )
    end

    it "returns an empty array when no sessionSignature is available" do
      session = described_class.new(
        "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
        "startDateTime" => "2026-01-05T10:00:00Z",
      )

      expect(session.meter_readings).to eq []
    end
  end

  describe "#energy_details" do
    it "parses the per-timestamp energy readings when present" do
      session = described_class.new(
        "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
        "startDateTime" => "2026-01-05T10:00:00Z",
        "energyDetails" => [
          { "timestamp" => "2026-01-05T10:15:00Z", "energy" => 1.5 },
          { "timestamp" => "2026-01-05T10:30:00Z", "energy" => 3.2 },
        ],
      )

      expect(session.energy_details).to match(
        [
          have_attributes(timestamp: Time.zone.parse("2026-01-05T10:15:00Z"), energy_kwh: 1.5),
          have_attributes(timestamp: Time.zone.parse("2026-01-05T10:30:00Z"), energy_kwh: 3.2),
        ],
      )
    end

    it "returns an empty array when the API omits the readings" do
      session = described_class.new(
        "id" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
        "startDateTime" => "2026-01-05T10:00:00Z",
      )

      expect(session.energy_details).to eq []
    end
  end
end
