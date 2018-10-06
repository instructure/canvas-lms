#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'json/jwt'

module Lti
  module Oauth2
    class AuthorizationValidator
      class InvalidSignature < StandardError
      end
      class SecretNotFound < StandardError
      end
      class InvalidAuthJwt < StandardError
      end
      class MissingAuthorizationCode < StandardError
      end

      def initialize(jwt:, authorization_url:, code: nil, context:)
        @raw_jwt = jwt
        @authorization_url = authorization_url
        @code = code
        @context = context
      end

      def jwt
        @_jwt ||= begin
          validated_jwt = JSON::JWT.decode @raw_jwt, jwt_secret
          validator = Canvas::Security::JwtValidator.new jwt: validated_jwt, expected_aud: @authorization_url, override_sub: sub
          unless validator.valid?
            raise InvalidAuthJwt, validator.error_message
          end
          validated_jwt
        end
      end

      alias_method :validate!, :jwt

      def tool_proxy
        @_tool_proxy ||= begin
          tp = ToolProxy.where(guid: unverified_jwt[:sub], workflow_state: 'active').first
          return nil unless tp.present?
          developer_key = tp.product_family.developer_key
          raise InvalidAuthJwt, "the Developer Key is not active or available in this environment" if developer_key.present? && !developer_key.usable?
          ims_tool_proxy = IMS::LTI::Models::ToolProxy.from_json(tp.raw_data)
          if (ims_tool_proxy.enabled_capabilities & ['Security.splitSecret', 'OAuth.splitSecret']).blank?
            raise InvalidAuthJwt, "the Tool Proxy must be using a split secret"
          end
          tp
        end
      end

      def developer_key
        @_developer_key ||= begin
          dev_key = DeveloperKey.find_cached(unverified_jwt[:sub])
          raise MissingAuthorizationCode if dev_key && @code.blank?
          dev_key
        rescue ActiveRecord::RecordNotFound
          return nil
        end
      end

      def sub
        tool_proxy&.guid || developer_key&.global_id || unverified_jwt[:sub]
      end

      private

      def jwt_secret
        secret = tool_proxy&.shared_secret
        secret ||= developer_key&.api_key
        secret ||= (RegistrationRequestService.retrieve_registration_password(@context, unverified_jwt[:sub]) || {})[:reg_password]
        return secret if secret.present?
        raise SecretNotFound, "either the tool proxy or developer key were not found"
      end

      def unverified_jwt
        @_unverified_jwt ||= begin
          decoded_jwt = JSON::JWT.decode(@raw_jwt, :skip_verification)
          decoded_jwt
        end
      end
    end
  end
end
