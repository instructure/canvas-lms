
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

module Canvas::Oauth
  class ClientCredentialsProvider < Provider
    def initialize(client_id, host, scopes = nil, protocol = 'http://')
      @client_id = client_id
      @scopes = scopes || []
      @expected_aud = Rails.application.routes.url_helpers.oauth2_token_url(
        host: host,
        protocol: protocol
      )
    end

    def generate_token
      claims, scopes, ttl = generate_claims
      {
        access_token: key.issue_token(claims),
        token_type: 'Bearer',
        expires_in: ttl.seconds,
        scope: scopes
      }
    end

    def valid?
      raise 'Abstract Method'
    end

    def error_message
      raise 'Abstract Method'
    end

    private

    def allowed_scopes
      @allowed_scopes ||= @scopes.join(' ')
    end

    def generate_claims
      scopes = allowed_scopes
      timestamp = Time.zone.now.to_i
      ttl = Setting.get("oauth2_jwt_exp_in_seconds", 1.hour.to_s).to_i
      claims = {
        iss: Canvas::Security.config['lti_iss'],
        sub: @client_id,
        aud: @expected_aud,
        iat: timestamp,
        exp: timestamp + ttl,
        jti: SecureRandom.uuid,
        scopes: scopes
      }
      if key.account_id
        # if developer key is account scoped, add namespaced custom claim about
        # account id
        claims["canvas.instructure.com"] = { "account_uuid" => key.account.uuid }
      end
      return claims, scopes, ttl
    end
  end

  class AsymmetricClientCredentialsProvider < ClientCredentialsProvider
    def initialize(jwt, host, scopes = nil, protocol = 'http://')
      super(JSON::JWT.decode(jwt, :skip_verification)[:sub], host, scopes, protocol)
      @errors = []
      if key.nil? || (key.public_jwk.nil? && key.public_jwk_url.nil?)
        @invalid_key = true
      else
        decoded_jwt(jwt)
      end
    end

    def valid?
      return false if @invalid_key
      validator.valid?
    end

    def error_message
      return 'JWS signature invalid.' if @invalid_key
      return "JWK Error: #{errors.first.message}" if errors.present?
      validator.error_message
    end

    private

    attr_accessor :errors

    def validator
      @validator ||= Canvas::Security::JwtValidator.new(
        jwt: decoded_jwt,
        expected_aud: @expected_aud,
        full_errors: true,
        require_iss: true,
        skip_jti_check: true
      )
    end

    def decoded_jwt(jwt = nil)
      @decoded_jwt ||= if key.public_jwk_url.present?
          get_jwk_from_url(jwt)
        else
          JSON::JWT.decode(jwt, JSON::JWK.new(key.public_jwk), :RS256)
        end
    rescue JSON::JWS::VerificationFailed, JSON::JWS::UnexpectedAlgorithm
      @invalid_key = true
    end

    def get_jwk_from_url(jwt = nil)
      pub_jwk_from_url = HTTParty.get(key.public_jwk_url)
      JSON::JWT.decode(jwt, JSON::JWK::Set.new(pub_jwk_from_url.parsed_response))
    rescue JSON::JWT::Exception => e
      errors << e
      raise JSON::JWS::VerificationFailed
    end
  end

  class SymmetricClientCredentialsProvider < ClientCredentialsProvider
    def valid?
      key.present?
    end

    def error_message
      valid? ? "" : "Unknown client_id"
    end
  end
end
