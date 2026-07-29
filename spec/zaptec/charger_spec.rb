RSpec.describe Zaptec::Charger do
  describe "#current_user_roles" do
    it "reads the CurrentUserRoles bitmask" do
      charger = build_charger(CurrentUserRoles: Zaptec::Charger::USER_ROLE | Zaptec::Charger::OWNER_ROLE)

      expect(charger.current_user_roles).to eq(3)
    end

    it "defaults to None when the field is absent" do
      charger = build_charger

      expect(charger.current_user_roles).to eq(0)
    end
  end

  describe "role predicates" do
    it "recognises the Owner role in the bitmask" do
      charger = build_charger(CurrentUserRoles: Zaptec::Charger::OWNER_ROLE | Zaptec::Charger::MAINTAINER_ROLE)

      expect(charger).to be_owner
      expect(charger).to be_maintainer
      expect(charger).not_to be_user
      expect(charger).not_to be_technical
    end

    it "is not an owner when only a lower role remains" do
      charger = build_charger(CurrentUserRoles: Zaptec::Charger::MAINTAINER_ROLE)

      expect(charger).not_to be_owner
    end

    it "has no roles when the field is absent" do
      charger = build_charger

      expect(charger).not_to be_owner
      expect(charger).not_to be_user
      expect(charger).not_to be_maintainer
    end
  end

  describe "#role_names" do
    it "lists the roles present in the bitmask" do
      charger = build_charger(CurrentUserRoles: Zaptec::Charger::OWNER_ROLE | Zaptec::Charger::TECHNICAL_ROLE)

      expect(charger.role_names).to contain_exactly(:owner, :technical)
    end

    it "is empty without any roles" do
      expect(build_charger.role_names).to eq([])
    end
  end

  describe "#service_level_technical_read_access?" do
    it "is true when the flag is set" do
      charger = build_charger(CurrentUserHasServiceLevelTechnicalReadAccess: true)

      expect(charger).to be_service_level_technical_read_access
    end

    it "is false when the flag is absent" do
      expect(build_charger).not_to be_service_level_technical_read_access
    end
  end

  def build_charger(**overrides)
    Zaptec::Charger.new(
      {
        Id: "93d603a7-ff53-4ed8-8dd6-f79c94819458",
        Name: "Zaptec",
        DeviceId: "ZAP049387",
        DeviceType: 4,
        InstallationName: "Zaptechof 1",
        InstallationId: "2bbec6f9-c3ce-4edf-a72f-b1b2a663c6ba",
      }.merge(overrides),
    )
  end
end
