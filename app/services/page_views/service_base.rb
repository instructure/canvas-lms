# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module PageViews
  class ServiceBase
    def initialize(configuration, requestor_user: nil)
      @configuration = configuration
      @requestor_user = requestor_user
    end

    protected

    attr_reader :configuration

    def request_headers
      request_id = RequestContext::Generator.request_id
      jwt_token = generate_jwt_token
      { "Authorization" => "Bearer #{jwt_token}",
        "X-Request-Context-Id" => request_id }
    end

    def generate_jwt_token
      raise ArgumentError, "requestor_user is required for JWT generation" unless @requestor_user

      domain = @configuration.uri.host
      CanvasSecurity::ServicesJwt.for_user(
        domain,
        @requestor_user,
        encrypt: false,
        base64: false
      )
    end

    def get_with_clean_redirect(uri, headers, &)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.ssl_timeout = http.open_timeout = CanvasHttp::OPEN_TIMEOUT
      http.read_timeout = CanvasHttp::READ_TIMEOUT
      http.write_timeout = CanvasHttp::WRITE_TIMEOUT
      http.max_retries = 0
      response = http.request(Net::HTTP::Get.new(uri.request_uri, headers))

      if response.is_a?(Net::HTTPRedirection)
        redirect_url = response["Location"]
        raise "Redirect response is missing a Location header" unless redirect_url

        CanvasHttp.get(redirect_url, &)
      else
        yield response
      end
    end

    def handle_generic_errors(response)
      case response.code.to_i
      when 400
        error_messages = extract_error_messages_if_present(response)
        detail = error_messages.any? ? error_messages.join(", ") : response.body
        raise Common::InvalidRequestError, "Invalid request: #{detail}"
      when 403
        raise Common::AccessDeniedError, "Access denied to the requested resource"
      when 404
        raise Common::NotFoundError, "Resource not found"
      when 429
        raise Common::TooManyRequestsError, "Rate limit exceeded"
      when 204
        raise Common::NoContentError, "Empty result, no content available"
      when 500
        raise Common::InternalServerError, "Internal server error"
      when 503
        raise Common::ServiceUnavailable, "Service temporarily unavailable"
      else
        raise "Unexpected response: #{response.code}"
      end
    end

    def extract_error_messages_if_present(response)
      errors = JSON.parse(response.body)["errors"]
      Array(errors).compact
    rescue JSON::ParserError
      []
    end
  end
end
