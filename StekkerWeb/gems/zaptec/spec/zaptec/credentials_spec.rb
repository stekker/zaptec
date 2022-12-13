RSpec.describe Zaptec::Credentials do
  describe "#expired?" do
    it "knows when it's expired" do
      expect(Zaptec::Credentials.new("abc", 1.hour.ago)).to be_expired
      expect(Zaptec::Credentials.new(nil, nil)).to be_expired
      expect(Zaptec::Credentials.new("abc", 1.hour.from_now)).not_to be_expired
    end
  end
end
