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
end
