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

module MicrosoftSync
  module Errors
    # When the sync job fails, we show an error to the user. PublicError is a
    # generic message unless the error raised is a PublicError. Custom error
    # classes can extend PublicError; they should define the following:
    # * `self.public_message`: a constant value (e.g. string, or a hash with "one" and
    #   "other" -- see I18nlinter documentation) wrapped in I18n.t() so it will
    #   be extracted for internationalization; however, the value will be
    #   actually localized when shown in the UI with deserialize_and_localize().
    #   You may use interpolated placeholders like %{count}, but do not pass in
    #   any values for them.
    # * (Optional) `public_interpolated_values`, a hash of values that will
    #   be passed in to I18n.t!() along with the public_message when the error
    #   message is localized and shown to the user.
    #
    # When an error happens in a job, we can then use serialize() to turn it into
    # a JSON blob with the unlocalized message and interpolation values. When the user
    # views the Course settings which shows the error, we call deserialize_and_localize()
    # which localizes the error into whatever language that user is using.
    class PublicError < StandardError
      def self.public_message; end

      def public_interpolated_values; end
    end

    class << self
      # Returns a JSONified hash with class, message, public_message, and
      # public_interpolated_values. class and message are for internal debugging only.
      def serialize(error, **extra_metadata)
        result = {
          class: error.class.name,
          message: error.message&.truncate(1000),
          extra_metadata:
        }

        if error.is_a?(MicrosoftSync::Errors::PublicError)
          I18n.with_locale(:en) do
            # force passthrough call to I18n() in public_message() to return original value,
            # will be localized in deserialize_and_localize()
            result[:public_message] = error.class.public_message
            result[:public_interpolated_values] = error.public_interpolated_values
          end
        end

        result.compact.to_json
      end

      def extra_metadata_from_serialized(serialized_error)
        return {} unless serialized_error

        deserialize(serialized_error)[:extra_metadata] || {}
      end

      # Takes an string returned by serialize() and returns the error
      # message to be shown to users, localized to the current locale.
      def deserialize_and_localize(serialized_error)
        return nil unless serialized_error

        deserialized = deserialize(serialized_error)
        if deserialized.nil?
          # probably old style, just a string
          serialized_error
        elsif deserialized[:public_message]
          msg = deserialized[:public_message]
          interpolations = deserialized[:public_interpolated_values]
          I18n.t!(msg, interpolations || {})
        else
          I18n.t("Microsoft Sync has encountered an internal error.")
        end
      end

      private

      def deserialize(err)
        # I18n interpolations and message ("one"/"multiple") have to have symbol keys
        deserialized = JSON.parse(err, symbolize_names: true)
        deserialized if deserialized.is_a?(Hash) && deserialized[:class]
      rescue JSON::ParserError
        nil
      end
    end

    # Signals to StateMachineJob that an error is not entirely unexpected. It should
    # quit the job and report the error to the user, but not report to Canvas::Errors
    class GracefulCancelError < PublicError; end

    # This is used internally and retried (due to Microsoft's inconsistent API), but if it still
    # fails after retry, could indicate we need to up the backoff times, or indicate some other
    # unknown problem.
    class GroupHasNoOwners < PublicError
      def self.public_message
        I18n.t "The team could be not be created because the Microsoft group has no owners. " \
               "This may be an intermittent error: please try to sync again, and " \
               "if the problem persists, contact support."
      end
    end

    # When we know the team has been created so we know there are really no teachers
    # (or possibly, in the case of partial sync, some have been manually removed)
    class MissingOwners < Errors::GracefulCancelError
      def self.public_message
        I18n.t "A Microsoft 365 Group must have owners, and no users " \
               "corresponding to the instructors of the Canvas course could be found on the " \
               "Microsoft side. If you recently added and removed course owners, a re-sync " \
               "may resolve the issue."
      end
    end

    class NotEducationTenant < Errors::GracefulCancelError
      def self.public_message
        I18n.t "The Microsoft 365 tenant provided in account settings is not an Education " \
               "tenant, so cannot be used with the Microsoft Teams Sync integration."
      end
    end

    class GroupNotFoundGracefulCancelError < Errors::GracefulCancelError
      def self.public_message
        I18n.t "The Microsoft 365 Group created by sync no longer exists. Usually, this means " \
               "the group was deleted on the Microsoft side (e.g., by an admin). A manual " \
               "re-sync should resolve the issue and recreate the group if necessary."
      end
    end

    class TeamAlreadyExists < StandardError; end

    class GroupNotFound < StandardError; end

    class OwnersQuotaExceeded < StandardError; end

    class MembersQuotaExceeded < StandardError; end

    # Makes public the status code but not anything about the response body.
    # The internal error message has the response body (truncated)
    # Use for() instead of new; this creates a subclass based on the status
    # code, which allows consumers to select semi-expected cases if they need to.
    class HTTPInvalidStatus < PublicError
      attr_reader :response
      attr_reader :code

      def self.public_message
        I18n.t "Unexpected response from Microsoft API: got %{status_code} status code"
      end

      def public_interpolated_values
        { status_code: code }
      end

      def self.subclasses_by_status_code
        @subclasses_by_status_code ||= {
          400 => HTTPBadRequest,
          404 => HTTPNotFound,
          409 => HTTPConflict,
          424 => HTTPFailedDependency,
          429 => HTTPTooManyRequests,
          500 => HTTPInternalServerError,
          502 => HTTPBadGateway,
          503 => HTTPServiceUnavailable,
          504 => HTTPGatewayTimeout,
        }
      end

      def self.for(service:, response:, tenant:)
        klass = subclasses_by_status_code[response.code] || self
        klass.new(service:, response:, tenant:)
      end

      def initialize(service:, response:, tenant:)
        @response = response
        @code = response.code
        super(
          "#{service.capitalize} service returned #{response.code} for tenant #{tenant}, " \
          "full body: #{response.body.inspect.truncate(1000)}"
        )
      end
    end

    # Mixin for errors that are considered 'throttled'
    module Throttled
      attr_reader :retry_after_seconds
    end

    class HTTPNotFound < HTTPInvalidStatus; end

    class HTTPBadRequest < HTTPInvalidStatus; end

    class HTTPConflict < HTTPInvalidStatus; end

    class HTTPFailedDependency < HTTPInvalidStatus; end

    class HTTPInternalServerError < HTTPInvalidStatus; end

    class HTTPBadGateway < HTTPInvalidStatus; end

    class HTTPServiceUnavailable < HTTPInvalidStatus; end

    class HTTPGatewayTimeout < HTTPInvalidStatus; end

    class HTTPTooManyRequests < HTTPInvalidStatus
      include Throttled

      def initialize(**args)
        @retry_after_seconds = args[:response].headers["Retry-After"].presence&.to_f
        super(**args)
      end
    end

    INTERMITTENT = [
      EOFError,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Errno::ETIMEDOUT,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      OpenSSL::SSL::SSLError,
      SocketError,
      Timeout::Error,

      HTTPBadGateway,
      HTTPGatewayTimeout,
      HTTPInternalServerError,
      HTTPServiceUnavailable,

      Throttled,
    ].freeze

    # Microsoft's API being eventually consistent requires us to retry 404s
    # (HTTPNotFound) is many cases, particularly when first adding a group.
    NOT_FOUND = [HTTPNotFound, GroupNotFound].freeze

    INTERMITTENT_AND_NOTFOUND = [*INTERMITTENT, *NOT_FOUND].freeze
  end
end
