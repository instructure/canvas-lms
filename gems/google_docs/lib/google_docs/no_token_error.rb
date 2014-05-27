module GoogleDocs
  class NoTokenError < StandardError
    def initialize
      super("User does not have a valid Google Docs token")
    end
  end
end