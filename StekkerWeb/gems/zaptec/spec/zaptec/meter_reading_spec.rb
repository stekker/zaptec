RSpec.describe Zaptec::MeterReading do
  describe "::parse" do
    it "correctly parses a OCMF meter reading" do
      meter_reading = Zaptec::MeterReading.parse(example_meter_reading)

      expect(meter_reading)
        .to have_attributes(
          reading_kwh: 2935.6,
          timestamp: Time.find_zone!("UTC").local(2018, 7, 24, 11, 22, 4)
        )
    end

    it "support Wh readings" do
      meter_reading = Zaptec::MeterReading.parse(example_meter_reading(unit: "Wh", value: 2935.6 * 1000))

      expect(meter_reading).to have_attributes(reading_kwh: 2935.6)
    end
  end

  def example_meter_reading(unit: "kWh", value: 2935.6)
    <<~OCMF
      OCMF|{
          "FV": "1.0",
          "GI": "ABL SBC-301",
          "GS": "808829900001",
          "GV": "1.4p3",
          "PG": "T12345",
          "MV": "Phoenix Contact",
          "MM": "EEM-350-D-MCB",
          "MS": "BQ27400330016",
          "MF": "1.0",
          "IS": true,
          "IL": "VERIFIED",
          "IF": [
              "RFID_PLAIN",
              "OCPP_RS_TLS"
          ],
          "IT": "ISO14443",
          "ID": "1F2D3A4F5506C7",
          "RD": [
              {
                  "TM": "2018-07-24T13:22:04,000+0200 S",
                  "TX": "B",
                  "RV": #{value},
                  "RI": "1-b:1.8.0",
                  "RU": "#{unit}",
                  "RT": "AC",
                  "EF": "",
                  "ST": "G"
              }
          ]
      }|{
      "SD":  "887FABF407AC82782EEFFF2220C2F856AEB0BC22364BBCC6B55761911ED651D1A922BADA88818C9671AFEE7094D7F536"
      }
    OCMF
  end
end
