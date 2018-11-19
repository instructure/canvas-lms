#
# Copyright (C) 2018 - present Instructure, Inc.
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
  module AdvantageServices
    extend ActiveSupport::Concern

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
          require_iss: true
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

    # rubocop:disable Metrics/BlockLength
    included do
      before_action(
        :verify_environment,
        :verify_access_token,
        :verify_context,
        :verify_developer_key,
        :verify_tool,
        :verify_tool_permissions,
        :verify_tool_features,
      )

      def verify_environment
        # TODO: Take out when 1.3/Advantage fully baked. See same hack in Lti::Ims::Concerns::GradebookServices,
        # which we can probably change to just include this module.
        render_unauthorized_action if Rails.env.production?
      end

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

      def verify_context
        render_error("Context not found", :not_found) if context.blank?
      end

      def verify_developer_key
        unless developer_key&.active?
          render_error("Unknown or inactive Developer Key", :unauthorized)
          return
        end
        unless context&.account.present? && developer_key.binding_on_in_account?(context.account)
          render_error("Invalid Developer Key", :unauthorized)
          return
        end
      end

      def verify_tool
        render_error("Access Token not linked to a Tool associated with this Context", :unauthorized) if tool.blank?
      end

      def verify_tool_permissions
        render_error("Insufficient permissions", :unauthorized) unless tool_permissions_granted?
      end

      def verify_tool_features
        render_error("LTI 1.3/Advantage features not enabled", :unauthorized) unless tool&.lti_1_3_enabled?
      end

      def access_token
        @_access_token ||= begin
          raw_jwt_str = AuthenticationMethods.access_token(request)
          AccessToken.new(raw_jwt_str) if raw_jwt_str.present?
        end
      end

      def expected_access_token_audience
        Rails.application.routes.url_helpers.oauth2_token_url host: host
      end

      delegate :host, to: :request

      def tool_permissions_granted?
        raise 'Abstract Method'
      end

      def developer_key
        @_developer_key ||= access_token && begin
          DeveloperKey.find_cached(access_token.claim('sub'))
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end

      def context
        raise 'Abstract Method'
      end

      def tool
        @_tool ||= begin
          return nil unless context
          return nil unless developer_key
          ContextExternalTool.all_tools_for(context).where(developer_key: developer_key).take
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
