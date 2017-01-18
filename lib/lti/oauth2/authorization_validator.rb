require 'json/jwt'

module Lti
  module Oauth2
    class AuthorizationValidator
      class InvalidSignature < StandardError
      end
      class ToolProxyNotFound < StandardError
      end
      class InvalidAuthJwt < StandardError
      end

      def initialize(jwt:, authorization_url:)
        @raw_jwt = jwt
        @authorization_url = authorization_url
      end

      def jwt
        @_jwt ||= begin
          validated_jwt = JSON::JWT.decode @raw_jwt, tool_proxy.shared_secret
          check_required_assertions(validated_jwt.keys)
          %w(iss sub).each do |assertion|
            if validated_jwt[assertion] != tool_proxy.guid
              raise InvalidAuthJwt, "the '#{assertion}' must be a valid ToolProxy guid"
            end
          end
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
          tp = ToolProxy.where(guid: unverified_jwt.kid, workflow_state: 'active').first
          raise ToolProxyNotFound if tp.blank?
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


      private

      def check_required_assertions(assertion_keys)
        missing_assertions = (%w(iss sub aud exp iat jti) - assertion_keys)
        if missing_assertions.present?
          raise InvalidAuthJwt, "the following assertions are missing: #{missing_assertions.join(',')}"
        end
      end

      def unverified_jwt
        @_unverified_jwt ||= begin
          decoded_jwt = JSON::JWT.decode(@raw_jwt, :skip_verification)
          raise InvalidAuthJwt, "the 'kid' header is required" if decoded_jwt.kid.blank?
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
