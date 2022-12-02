require "faraday"
require "faraday_middleware"
require "faraday/detailed_logger"
require "faraday-cookie_jar"
require "active_model"
require "active_support/all"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Zaptec
end
