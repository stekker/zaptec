RSpec.describe Zaptec::State do
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
