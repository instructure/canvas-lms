module IncomingMail
  class SilentIgnoreError < StandardError; end
  class ReplyFromError < StandardError; end
  class UnknownAddressError < ReplyFromError; end
  class ReplyToLockedTopicError < ReplyFromError; end
end