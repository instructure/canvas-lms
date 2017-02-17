module Lti
  module Errors
    class UnauthorizedError < StandardError; end
    class UnsupportedExportTypeError < StandardError; end
    class UnsupportedMessageTypeError < StandardError; end
    class InvalidMediaTypeError < StandardError; end
  end
end
