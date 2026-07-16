RSpec.describe Zaptec::Session do
  it "exposes the session fields" do
    session = described_class.new(
      "sessionId" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "sessionStart" => "2026-01-05T10:00:00Z",
      "sessionEnd" => "2026-01-05T11:30:00Z",
      "energy" => 12.34,
      "signedSession" => "OCMF-signature-blob",
    )

    expect(session).to have_attributes(
      id: "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      session_start: Time.zone.parse("2026-01-05T10:00:00Z"),
      session_end: Time.zone.parse("2026-01-05T11:30:00Z"),
      energy_kwh: 12.34,
      signed_session: "OCMF-signature-blob",
    )
  end

  it "returns nil for session_end and signed_session when the session is still ongoing" do
    session = described_class.new(
      "sessionId" => "b1e5a5f0-1111-4c8b-9d2f-000000000001",
      "sessionStart" => "2026-01-05T10:00:00Z",
      "sessionEnd" => nil,
      "energy" => 0.0,
      "signedSession" => nil,
    )

    expect(session).to have_attributes(
      session_end: nil,
      signed_session: nil,
    )
  end
end
