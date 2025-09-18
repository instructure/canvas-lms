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
      headers = { "Authorization" => "Bearer #{@configuration.access_token}",
                  "X-Request-Context-Id" => request_id }
      headers["X-Canvas-User-Id"] = @requestor_user.global_id.to_s if @requestor_user
      headers
    end

    def handle_generic_errors(response)
      case response.code.to_i
      when 400
        error_messages = extract_error_messages_if_present(response)
        raise Common::InvalidRequestError, "Invalid request: #{error_messages.join(", ")}"
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
      else
        raise "Unexpected response: #{response.code}"
      end
    end

    def extract_error_messages_if_present(response)
      errors = JSON.parse(response.body)["errors"]
      errors.is_a?(Array) ? errors : [errors]
    rescue JSON::ParserError
      nil
    end
  end
end
