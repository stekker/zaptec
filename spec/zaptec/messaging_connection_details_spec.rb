RSpec.describe Zaptec::MessagingConnectionDetails do
  it "exposes the connection settings" do
    details = described_class.new(
      "Type" => 0,
      "Host" => "zap-p-installations-sbus.servicebus.windows.net",
      "Port" => 5671,
      "UseSSL" => true,
      "Username" => "usergroup_abc",
      "Password" => "secret",
      "Topic" => "usergroup_abc",
      "Subscription" => "default",
    )

    expect(details).to have_attributes(
      host: "zap-p-installations-sbus.servicebus.windows.net",
      port: 5671,
      use_ssl: true,
      username: "usergroup_abc",
      password: "secret",
      topic: "usergroup_abc",
      subscription: "default",
    )
  end
end
