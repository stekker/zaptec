module Zaptec
  class MessagingConnectionDetails
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def host = @data.fetch(:Host)
    def port = @data.fetch(:Port)
    def use_ssl = @data.fetch(:UseSSL)
    def username = @data.fetch(:Username)
    def password = @data.fetch(:Password)
    def topic = @data.fetch(:Topic)
    def subscription = @data.fetch(:Subscription)
  end
end
