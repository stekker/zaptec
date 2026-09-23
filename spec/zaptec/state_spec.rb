RSpec.describe Zaptec::State do
  describe "#total_charge_power_session" do
    it "reads TotalChargePowerSession as a float" do
      state = Zaptec::State.new(TotalChargePowerSession: "1.42012")

      expect(state.total_charge_power_session).to eq 1.42012
    end

    it "is nil when the TotalChargePowerSession observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state.total_charge_power_session).to be_nil
    end

    it "is nil when the TotalChargePowerSession observation has no value" do
      state = Zaptec::State.new(TotalChargePowerSession: nil)

      expect(state.total_charge_power_session).to be_nil
    end
  end

  describe "#total_charge_power" do
    it "reads TotalChargePower as a float" do
      state = Zaptec::State.new(TotalChargePower: "2.83012")

      expect(state.total_charge_power).to eq 2.83012
    end

    it "is nil when the TotalChargePower observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state.total_charge_power).to be_nil
    end
  end

  describe "#max_charge_current" do
    it "reads ChargerMaxCurrent as a float" do
      state = Zaptec::State.new(ChargerMaxCurrent: "10")

      expect(state.max_charge_current).to eq 10.0
    end

    it "is nil when the ChargerMaxCurrent observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state.max_charge_current).to be_nil
    end
  end

  describe "#max_phases" do
    it "reads MaxPhases as an integer" do
      state = Zaptec::State.new(MaxPhases: "3")

      expect(state.max_phases).to eq 3
    end

    it "is nil when the MaxPhases observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state.max_phases).to be_nil
    end
  end

  describe "#operation_mode" do
    it "names the mode reported by ChargerOperationMode" do
      state = Zaptec::State.new(ChargerOperationMode: "3")

      expect(state.operation_mode).to eq "Connected_Charging"
    end

    it "is Unknown when the ChargerOperationMode observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state.operation_mode).to eq "Unknown"
      expect(state).not_to be_charging
      expect(state).not_to be_disconnected
      expect(state).not_to be_paused
    end
  end

  describe "#final_stop_active?" do
    it "is true when FinalStopActive is 1" do
      state = Zaptec::State.new(FinalStopActive: "1")

      expect(state).to be_final_stop_active
    end

    it "is false when FinalStopActive is 0" do
      state = Zaptec::State.new(FinalStopActive: "0")

      expect(state).not_to be_final_stop_active
    end

    it "is false when the FinalStopActive observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state).not_to be_final_stop_active
    end
  end

  describe "#online?" do
    it "is true when IsOnline is 1" do
      state = Zaptec::State.new(IsOnline: "1")

      expect(state).to be_online
    end

    it "is false when IsOnline is 0" do
      state = Zaptec::State.new(IsOnline: "0")

      expect(state).not_to be_online
    end

    it "is false when the IsOnline observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state).not_to be_online
    end
  end

  describe "#meter_reading" do
    it "parses the signed meter value when present" do
      state = Zaptec::State.new(SignedMeterValue: example_meter_reading)

      expect(state.meter_reading).to have_attributes(reading_kwh: 2935.6)
    end

    it "is nil when the SignedMeterValue observation is missing from the API response" do
      state = Zaptec::State.new({})

      expect(state.meter_reading).to be_nil
    end
  end

  def example_meter_reading
    <<~OCMF
      OCMF|{
          "FV": "1.0",
          "RD": [
              {
                  "TM": "2018-07-24T13:22:04,000+0200 S",
                  "RV": 2935.6,
                  "RU": "kWh",
                  "ST": "G"
              }
          ]
      }|{"SD":"abc"}
    OCMF
  end
end
