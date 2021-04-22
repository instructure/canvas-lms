# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#

# When the sync job fails, we show an error to the user. Because internal error
# messages may not be safe to show to the user, we opt-in to showing the user
# the message for certain errors by making it a PublicError, which provides a
# public_message. This defaults to just the error `message` but can be
# overridden, in case we want to display a different message to users than what
# is in our logs/failed job/etc.
module MicrosoftSync
  module Errors
    def self.user_facing_message(error)
      error_name = error.class.name.underscore.split(%r{[_/]}).map(&:capitalize).join(' ')

      if error.is_a?(MicrosoftSync::Errors::PublicError) && error.public_message.present? &&
          error.public_message != error.class.name
        "#{error_name}: #{error.public_message}"
      else
        error_name
      end
    end

    class PublicError < StandardError
      def public_message
        message
      end
    end

    class InvalidRemoteState < PublicError; end
    class GroupHasNoOwners < PublicError; end
    class TeamAlreadyExists < PublicError; end

    # Makes public the status code but not anything about the response body.
    # The internal error message has the response body (truncated)
    # Use for() instead of new; this creates a subclass based on the status
    # code, which allows consumers to select semi-expected cases if they need to.
    class HTTPInvalidStatus < PublicError
      attr_reader :public_message
      attr_reader :response_body
      attr_reader :code

      def self.subclasses_by_status_code
        @subclasses_by_status_code ||= {
          400 => HTTPBadRequest,
          404 => HTTPNotFound,
          409 => HTTPConflict,
          500 => HTTPInternalServerError,
          502 => HTTPBadGateway,
          503 => HTTPServiceUnavailable,
          504 => HTTPGatewayTimeout,
        }
      end

      def self.for(service:, response:, tenant:)
        klass = subclasses_by_status_code[response.code] || self
        klass.new(service: service, response: response, tenant: tenant)
      end

      def initialize(service:, response:, tenant:)
        @response_body = response.body
        @code = response.code
        @public_message = "#{service.capitalize} service returned #{response.code} for tenant #{tenant}"
        super("#{@public_message}, full body: #{response.body.inspect.truncate(1000)}")
      end
    end

    class HTTPNotFound < HTTPInvalidStatus; end
    class HTTPBadRequest < HTTPInvalidStatus; end
    class HTTPConflict < HTTPInvalidStatus; end
    class HTTPInternalServerError < HTTPInvalidStatus; end
    class HTTPBadGateway < HTTPInvalidStatus; end
    class HTTPServiceUnavailable < HTTPInvalidStatus; end
    class HTTPGatewayTimeout < HTTPInvalidStatus; end

    INTERMITTENT = [
      EOFError,
      Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EINVAL, Errno::ETIMEDOUT,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
      OpenSSL::SSL::SSLError,
      SocketError,
      Timeout::Error,

      HTTPBadGateway, HTTPGatewayTimeout, HTTPInternalServerError, HTTPServiceUnavailable,
    ].freeze

    # Microsoft's API being eventually consistent requires us to retry 404s
    # (HTTPNotFound) is many cases, particularly when first adding a group.
    INTERMITTENT_AND_NOTFOUND = [*INTERMITTENT, HTTPNotFound].freeze
  end
end
