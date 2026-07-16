module Zaptec
  class ArchivedSessionsPage
    attr_reader :sessions, :cursor

    def initialize(sessions:, cursor:, has_more:)
      @sessions = sessions
      @cursor = cursor
      @has_more = has_more
    end

    def has_more? = @has_more
  end
end
