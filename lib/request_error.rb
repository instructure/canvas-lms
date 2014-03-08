class RequestError < ::RuntimeError
  attr_accessor :response_status

  def initialize(message, status=:bad_request)
    self.response_status = Rack::Utils.status_code(status)
    super(message)
  end

  def error_json
    {
      status: (Rack::Utils::SYMBOL_TO_STATUS_CODE.key(self.response_status) || :internal_server_error).to_s,
      message: self.message
    }
  end
end
