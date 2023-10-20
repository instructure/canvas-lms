# frozen_string_literal: true

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

module Canvas::OAuth
  class AsymmetricClientCredentialsProvider < ClientCredentialsProvider
    def initialize(jwt, host, scopes: nil, protocol: "http://")
      super(JSON::JWT.decode(jwt, :skip_verification)[:sub], host, scopes:, protocol:)
      @errors = []
      if key.nil? || (key.public_jwk.nil? && key.public_jwk_url.nil?)
        @invalid_key = true
      else
        decoded_jwt(jwt)
      end
    end

    def valid?
      return false if @invalid_json
      return false if @invalid_key

      validator.valid?
    end

    def assertion_method_permitted?
      true
    end

    def error_message
      return "JWK Error: Invalid JSON" if @invalid_json
      return "JWS signature invalid." if @invalid_key
      return "JWK Error: #{errors.first.message}" if errors.present?

      validator.error_message
    end

    def secret
      key&.api_key
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
      pub_jwk_from_url = CanvasHttp.get(key.public_jwk_url)
      JSON::JWT.decode(jwt, JSON::JWK::Set.new(JSON.parse(pub_jwk_from_url.body)))
    rescue JSON::ParserError
      @invalid_json = true
    rescue CanvasHttp::Error, EOFError, JSON::JWT::Exception => e
      errors << e
      raise JSON::JWS::VerificationFailed
    end
  end
end
