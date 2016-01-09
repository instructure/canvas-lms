module Lti
  class ReRegConstraint

    RE_REG_HEADER = 'VND-IMS-CONFIRM-URL'.freeze

    def matches?(request)
      request.headers[RE_REG_HEADER].present? &&
          request.format == 'json'
    end

  end
end