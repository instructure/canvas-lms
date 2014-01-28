module Api::V1
  class ApiError < ::RuntimeError
    attr_accessor :response_status, :status

    def initialize(response_status, message)
      self.response_status = response_status
      self.status = Rack::Utils::HTTP_STATUS_CODES[self.response_status]
      self.status = self.status.underscore.to_sym

      super(message)
    end

    def error_json
      {
        status: self.status,
        message: self.message
      }
    end
  end
end
