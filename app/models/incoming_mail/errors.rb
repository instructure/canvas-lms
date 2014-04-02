module IncomingMail
  module Errors
    class SilentIgnore < StandardError; end
    class ReplyFrom < StandardError; end
    class UnknownAddress < ReplyFrom; end
    class ReplyToLockedTopic < ReplyFrom; end
  end
end