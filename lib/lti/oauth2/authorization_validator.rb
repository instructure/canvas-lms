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
          check_required_assertions(validated_jwt.keys)
          if validated_jwt['aud'] != @authorization_url
            raise InvalidAuthJwt, "the 'aud' must be the LTI Authorization endpoint"
          end
          validate_exp(validated_jwt['exp'])
          validate_iat(validated_jwt['iat'])
          validate_jti(
            jti: validated_jwt['jti'],
            sub: validated_jwt['sub'],
            exp: validated_jwt['exp'],
            iat: validated_jwt['iat']
          )
          validated_jwt
        end
      end

      alias_method :validate!, :jwt

      def tool_proxy
        @_tool_proxy ||= begin
          tp = ToolProxy.where(guid: unverified_jwt[:sub], workflow_state: 'active').first
          return nil unless tp.present?
          developer_key = tp.product_family.developer_key
          raise InvalidAuthJwt, "the Tool Proxy must be associated to a developer key" if developer_key.blank?
          raise InvalidAuthJwt, "the Developer Key is not active" unless developer_key.active?
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
        secret ||= RegistrationRequestService.retrieve_registration_password(@context, unverified_jwt[:sub])
        return secret if secret.present?
        raise SecretNotFound, "either the tool proxy or developer key were not found"
      end

      def check_required_assertions(assertion_keys)
        missing_assertions = (%w(sub aud exp iat jti) - assertion_keys)
        if missing_assertions.present?
          raise InvalidAuthJwt, "the following assertions are missing: #{missing_assertions.join(',')}"
        end
      end

      def unverified_jwt
        @_unverified_jwt ||= begin
          decoded_jwt = JSON::JWT.decode(@raw_jwt, :skip_verification)
          decoded_jwt
        end
      end

      def validate_exp(exp)
        exp_time = Time.zone.at(exp)
        max_exp_limit = Setting.get('lti.oauth2.authorize.max.expiration', 1.minute.to_s).to_i.seconds
        if exp_time > max_exp_limit.from_now
          raise InvalidAuthJwt, "the 'exp' must not be any further than #{max_exp_limit.seconds} seconds in the future"
        end
        raise InvalidAuthJwt, "the JWT has expired" if exp_time < Time.zone.now
      end

      def validate_iat(iat)
        iat_time = Time.zone.at(iat)
        max_iat_age = Setting.get('lti.oauth2.authorize.max_iat_age', 5.minutes.to_s).to_i.seconds
        if iat_time < max_iat_age.ago
          raise Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the 'iat' must be less than #{5.minutes} seconds old"
        end
        raise Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the 'iat' must not be in the future" if iat_time > Time.zone.now
      end

      def validate_jti(jti:, sub:, exp:, iat:)
        nonce_duration = (exp.to_i - iat.to_i).seconds
        nonce_key = "nonce:#{sub}:#{jti}"
        unless Lti::Security.check_and_store_nonce(nonce_key, iat, nonce_duration)
          raise Lti::Oauth2::AuthorizationValidator::InvalidAuthJwt, "the 'jti' is invalid"
        end
      end

    end
  end
end
