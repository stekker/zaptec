RSpec.configure do |config|
  config.before do
    WebMock.reset!
  end
end
