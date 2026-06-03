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
end
