RSpec.describe Zaptec::MeterReading do
  describe "::parse" do
    it "correctly parses a OCMF meter reading" do
      meter_reading = Zaptec::MeterReading.parse(example_meter_reading)

      expect(meter_reading)
        .to have_attributes(
          reading_kwh: 2935.6,
          timestamp: Time.find_zone!("UTC").local(2018, 7, 24, 11, 22, 4),
        )
    end

    it "support Wh readings" do
      meter_reading = Zaptec::MeterReading.parse(example_meter_reading(unit: "Wh", value: 2935.6 * 1000))

      expect(meter_reading).to have_attributes(reading_kwh: 2935.6)
    end
  end

  describe "::parse_all" do
    it "returns one reading per RD entry" do
      readings = Zaptec::MeterReading.parse_all(<<~OCMF)
        OCMF|{
            "FV": "1.0",
            "RD": [
                { "TM": "2026-01-05T10:00:00,000+00:00 R", "TX": "B", "RV": 100.0, "RU": "kWh", "ST": "G" },
                { "TM": "2026-01-05T11:00:00,000+00:00 R", "TX": "T", "RV": 103.5, "RU": "kWh", "ST": "G" },
                { "TM": "2026-01-05T12:00:00,000+00:00 R", "TX": "E", "RV": 110.2, "RU": "kWh", "ST": "G" }
            ]
        }|{"SD":"abc"}
      OCMF

      expect(readings).to match(
        [
          have_attributes(timestamp: Time.zone.parse("2026-01-05T10:00:00Z"), reading_kwh: 100.0),
          have_attributes(timestamp: Time.zone.parse("2026-01-05T11:00:00Z"), reading_kwh: 103.5),
          have_attributes(timestamp: Time.zone.parse("2026-01-05T12:00:00Z"), reading_kwh: 110.2),
        ],
      )
    end

    it "converts Wh readings to kWh" do
      readings = Zaptec::MeterReading.parse_all(<<~OCMF)
        OCMF|{
            "FV": "1.0",
            "RD": [
                { "TM": "2026-01-05T10:00:00,000+00:00 R", "TX": "B", "RV": 12000.0, "RU": "Wh", "ST": "G" }
            ]
        }|{"SD":"abc"}
      OCMF

      expect(readings).to match([have_attributes(reading_kwh: 12.0)])
    end

    it "skips readings with a non-good status or unsupported unit" do
      readings = Zaptec::MeterReading.parse_all(<<~OCMF)
        OCMF|{
            "FV": "1.0",
            "RD": [
                { "TM": "2026-01-05T10:00:00,000+00:00 R", "RV": 100.0, "RU": "kWh", "ST": "E" },
                { "TM": "2026-01-05T11:00:00,000+00:00 R", "RV": 103.5, "RU": "A",   "ST": "G" },
                { "TM": "2026-01-05T12:00:00,000+00:00 R", "RV": 110.2, "RU": "kWh", "ST": "G" }
            ]
        }|{"SD":"abc"}
      OCMF

      expect(readings.map(&:reading_kwh)).to eq [110.2]
    end

    it "returns an empty array for a blank payload" do
      expect(Zaptec::MeterReading.parse_all(nil)).to eq []
      expect(Zaptec::MeterReading.parse_all("")).to eq []
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
