require "zaptec"
require "webmock"
require "webmock/rspec"
require "timecop"

Dir["spec/support/**/*.rb"].each { |f| require_relative "../#{f}" }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:suite) { Time.zone_default = Time.find_zone!("UTC") }

  config.after { Timecop.return }

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
