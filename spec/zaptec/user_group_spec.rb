RSpec.describe Zaptec::UserGroup do
  it "exposes id and name from a Data envelope row" do
    user_group = described_class.new("Id" => "abc-123", "Name" => "Acme")

    expect(user_group).to have_attributes(id: "abc-123", name: "Acme")
  end

  it "accepts lowercase keys" do
    user_group = described_class.new("id" => "abc-123", "name" => "Acme")

    expect(user_group).to have_attributes(id: "abc-123", name: "Acme")
  end
end
