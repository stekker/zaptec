RSpec.describe Zaptec::MessagingSubscription do
  let(:connection_details) do
    Zaptec::MessagingConnectionDetails.new(
      "Type" => 0,
      "Host" => "sb.example.com",
      "Port" => 5671,
      "UseSSL" => true,
      "Username" => "usergroup_abc",
      "Password" => Base64.strict_encode64("secret"),
      "Topic" => "usergroup_abc",
      "Subscription" => "default",
    )
  end

  it "yields parsed messages with translated state names" do
    body = <<~BODY
      @string\x03http://schemas.microsoft.com/2003/10/Serialization/\xC3\xBE\xC3\xBF{"DeviceId":"ZAP018643","DeviceType":4,"ChargerId":"f94cb4fc-d717-4357-a541-3d54ed815792","StateId":553,"Timestamp":"2026-05-20T12:41:41.55472Z","ValueAsString":"13.463"}
    BODY

    WebMock::API
      .stub_request(:delete, "https://sb.example.com/usergroup_abc/subscriptions/default/messages/head")
      .with(query: { timeout: "30" })
      .to_return(status: 201, body:, headers: { "Content-Type" => "application/xml" })

    subscription = described_class.new(connection_details:)

    message = subscription.each_message.first

    expect(message).to have_attributes(
      device_id: "ZAP018643",
      device_type: 4,
      state_id: 553,
      state_name: :TotalChargePowerSession,
      timestamp: "2026-05-20T12:41:41.55472Z",
      value: "13.463",
    )
  end

  it "uses POST in peek mode and DELETE in consume mode" do
    stub_peek = WebMock::API
      .stub_request(:post, "https://sb.example.com/usergroup_abc/subscriptions/default/messages/head")
      .with(query: { timeout: "30" })
      .to_return(status: 204)
    stub_consume = WebMock::API
      .stub_request(:delete, "https://sb.example.com/usergroup_abc/subscriptions/default/messages/head")
      .with(query: { timeout: "30" })
      .to_return(status: 204)

    subscription = described_class.new(connection_details:)
    subscription.send(:fetch_one, mode: :peek, timeout: 30)
    subscription.send(:fetch_one, mode: :consume, timeout: 30)

    expect(stub_peek).to have_been_requested
    expect(stub_consume).to have_been_requested
  end

  it "sends a SharedAccessSignature Authorization header with the right skn" do
    stub = WebMock::API
      .stub_request(:delete, "https://sb.example.com/usergroup_abc/subscriptions/default/messages/head")
      .with(
        query: { timeout: "30" },
        headers: { "Authorization" => /SharedAccessSignature .+skn=usergroup_abc/ },
      )
      .to_return(status: 204)

    described_class.new(connection_details:).send(:fetch_one, mode: :consume, timeout: 30)

    expect(stub).to have_been_requested
  end

  it "raises AuthorizationFailed on 401" do
    WebMock::API
      .stub_request(:delete, "https://sb.example.com/usergroup_abc/subscriptions/default/messages/head")
      .with(query: { timeout: "30" })
      .to_return(status: 401, body: "<Error><Code>401</Code></Error>")

    subscription = described_class.new(connection_details:)

    expect { subscription.send(:fetch_one, mode: :consume, timeout: 30) }
      .to raise_error(Zaptec::Errors::AuthorizationFailed)
  end

  it "returns nil on 204 No Content" do
    WebMock::API
      .stub_request(:delete, "https://sb.example.com/usergroup_abc/subscriptions/default/messages/head")
      .with(query: { timeout: "30" })
      .to_return(status: 204)

    subscription = described_class.new(connection_details:)

    expect(subscription.send(:fetch_one, mode: :consume, timeout: 30)).to be_nil
  end
end
