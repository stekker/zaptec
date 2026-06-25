RSpec.describe Zaptec::Errors::RequestFailed do
  it "appends the body from a Faraday response hash to the message" do
    error = described_class.new("Request returned status 503", { body: "Service Unavailable" })

    expect(error.message).to eq("Request returned status 503: Service Unavailable")
  end

  it "appends the body from a Net::HTTP response object to the message" do
    response = instance_double(Net::HTTPResponse, body: "<html>nope</html>")

    error = described_class.new("503 Service Unavailable", response)

    expect(error.message).to eq("503 Service Unavailable: <html>nope</html>")
  end

  it "omits the body separator when no response is given" do
    error = described_class.new("something broke")

    expect(error.message).to eq("something broke")
  end

  it "omits the body separator when the body is blank" do
    error = described_class.new("Request returned status 500", { body: "" })

    expect(error.message).to eq("Request returned status 500")
  end

  it "exposes the original response object" do
    response = { status: 503, body: "down" }

    error = described_class.new("boom", response)

    expect(error.response).to eq(response)
  end
end
