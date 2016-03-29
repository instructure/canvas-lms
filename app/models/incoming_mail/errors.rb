module IncomingMail
  module Errors
    class SilentIgnore < StandardError; end
    class ReplyFrom < StandardError; end
    class UnknownAddress < ReplyFrom; end
    class UnknownSender < ReplyFrom; end
    class ReplyToLockedTopic < ReplyFrom; end
    class ReplyToDeletedDiscussion < ReplyFrom; end
  end
end
