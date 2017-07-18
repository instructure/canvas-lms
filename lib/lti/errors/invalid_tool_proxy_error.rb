module Lti::Errors
  class InvalidToolProxyError < RuntimeError

    def initialize(message = nil, json = {})
      super(message)
      @message = message
      @json = json
    end

    def as_json
      @json[:error] = @message if @message
      @json
    end

  end
end
