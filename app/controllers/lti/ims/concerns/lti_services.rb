# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Lti::Ims::Concerns
  module LtiServices
    extend ActiveSupport::Concern

    UNIVERSAL_GRANT_HOST = Canvas::Security.config['lti_grant_host'] ||
      'canvas.instructure.com'.freeze

    class AccessToken
      def initialize(raw_jwt_str)
        @raw_jwt_str = raw_jwt_str
      end

      def validate!(expected_audience)
        validate_claims!(expected_audience)
        self
      rescue Canvas::Security::InvalidToken => e
        case e.cause
        when JSON::JWT::InvalidFormat
          raise Lti::Ims::AdvantageErrors::MalformedAccessToken, e
        when JSON::JWS::UnexpectedAlgorithm
          raise Lti::Ims::AdvantageErrors::InvalidAccessTokenSignatureType, e
        when JSON::JWS::VerificationFailed
          raise Lti::Ims::AdvantageErrors::InvalidAccessTokenSignature, e
        else
          raise Lti::Ims::AdvantageErrors::InvalidAccessToken.new(e, api_message: 'Access token invalid - signature likely incorrect')
        end
      rescue JSON::JWT::Exception => e
        raise Lti::Ims::AdvantageErrors::InvalidAccessToken, e
      rescue Canvas::Security::TokenExpired => e
        raise Lti::Ims::AdvantageErrors::InvalidAccessTokenClaims.new(e, api_message: 'Access token expired')
      rescue Lti::Ims::AdvantageErrors::AdvantageServiceError
        raise
      rescue => e
        raise Lti::Ims::AdvantageErrors::AdvantageServiceError, e
      end

      def validate_claims!(expected_audience)
        validator = Canvas::Security::JwtValidator.new(
          jwt: decoded_jwt,
          expected_aud: expected_audience,
          require_iss: true,
          skip_jti_check: true,
          max_iat_age: Setting.get('oauth2_jwt_iat_ago_in_seconds', 60.minutes.to_s).to_i.seconds
        )

        # In this case we know the error message can just be safely shunted into the API response (in other cases
        # we're more wary about leaking impl details)
        unless validator.valid?
          raise Lti::Ims::AdvantageErrors::InvalidAccessTokenClaims.new(
            nil,
            api_message: "Invalid access token field/s: #{validator.error_message}"
          )
        end
      end

      def claim(name)
        decoded_jwt[name]
      end

      def decoded_jwt
        @_decoded_jwt = Canvas::Security.decode_jwt(@raw_jwt_str)
      end
    end

    # factories for array matchers typically returned by #scopes_matcher
    class_methods do
      def all_of(*items)
        -> (match_in) { items.present? && (items - match_in).blank? }
      end

      def any_of(*items)
        -> (match_in) { items.present? && (items & match_in).present? }
      end

      def any
        -> (_) { true }
      end

      def none
        -> (_) { false }
      end
    end

    # rubocop:disable Metrics/BlockLength
    included do
      skip_before_action :load_user

      before_action(
        :verify_access_token,
        :verify_developer_key,
        :verify_access_scope
      )

      def verify_access_token
        if access_token.blank?
          render_error("Missing access token", :unauthorized)
        else
          begin
            access_token.validate!(expected_access_token_audience)
          rescue Lti::Ims::AdvantageErrors::AdvantageClientError => e # otherwise it's a system error, so we want normal error trapping and rendering to kick in
            handled_error(e)
            render_error(e.api_message, e.status_code)
          end
        end
      end

      def verify_developer_key
        unless developer_key&.active?
          render_error("Unknown or inactive Developer Key", :unauthorized)
        end
      end

      def verify_access_scope
        render_error("Insufficient permissions", :unauthorized) unless tool_permissions_granted?
      end

      def access_token
        @_access_token ||= begin
          raw_jwt_str = AuthenticationMethods.access_token(request)
          AccessToken.new(raw_jwt_str) if raw_jwt_str.present?
        end
      end

      def expected_access_token_audience
        [request.host_with_port, UNIVERSAL_GRANT_HOST].map do |h|
          Rails.application.routes.url_helpers.oauth2_token_url(host: h, protocol: request.protocol)
        end
      end

      def access_token_scopes
        @_access_token_scopes ||= (access_token&.claim('scopes')&.split(' ').presence || [])
      end

      def tool_permissions_granted?
        scopes_matcher.call(access_token_scopes)
      end

      def scopes_matcher
        raise 'Abstract method'
      end

      def developer_key
        @_developer_key ||= access_token && begin
          DeveloperKey.find_cached(access_token.claim('sub'))
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end

      def render_error(message, status = :precondition_failed)
        error_response = {
          errors: {
            type: status,
            message: message
          }
        }
        render json: error_response, status: status
      end

      def handled_error(e)
        unless Rails.env.production?
          # These are all 'handled errors' so don't typically warrant logging in production envs, but in lower envs it
          # can be very handy to see exactly what went wrong. This specific log mechanism is nice, too, b/c it logs
          # backtraces from nested errors.
          logger.error(e.message)
          ErrorReport.log_exception(nil, e)
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
