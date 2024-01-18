# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Lti
  module IMS
    # Used to parse/validate JWT Tokens for LTI Advantage endpoints that use
    # client_credentials flow such as NRPS and AGS
    class AdvantageAccessToken
      def initialize(raw_jwt_str)
        @raw_jwt_str = raw_jwt_str
      end

      def validate!(expected_audience)
        validate_claims!(expected_audience)
        self
      rescue Canvas::Security::InvalidToken => e
        case e.cause
        when JSON::JWT::InvalidFormat
          raise AdvantageErrors::MalformedAccessToken, e
        when JSON::JWS::UnexpectedAlgorithm
          raise AdvantageErrors::InvalidAccessTokenSignatureType, e
        when JSON::JWS::VerificationFailed
          raise AdvantageErrors::InvalidAccessTokenSignature, e
        else
          raise AdvantageErrors::InvalidAccessToken.new(e, api_message: "Access token invalid - signature likely incorrect")
        end
      rescue JSON::JWT::Exception => e
        raise AdvantageErrors::InvalidAccessToken, e
      rescue Canvas::Security::TokenExpired => e
        raise AdvantageErrors::InvalidAccessTokenClaims.new(e, api_message: "Access token expired")
      rescue AdvantageErrors::AdvantageServiceError
        raise
      rescue => e
        raise AdvantageErrors::AdvantageServiceError, e
      end

      def validate_claims!(expected_audience)
        validator = Canvas::Security::JwtValidator.new(
          jwt: decoded_jwt,
          expected_aud: expected_audience,
          require_iss: true,
          skip_jti_check: true,
          max_iat_age: 60.minutes
        )

        # In this case we know the error message can just be safely shunted into the API response (in other cases
        # we're more wary about leaking impl details)
        unless validator.valid?
          raise AdvantageErrors::InvalidAccessTokenClaims.new(
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

      def client_id
        claim("sub")
      end
    end
  end
end
