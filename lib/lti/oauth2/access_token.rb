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

module Lti
  module Oauth2
    class AccessToken
      private_class_method :new

      ISS = 'Canvas'.freeze

      attr_reader :aud, :sub, :reg_key

      def self.create_jwt(aud:, sub:, reg_key: nil)
        new(aud: aud, sub: sub, reg_key: reg_key)
      end

      def self.from_jwt(aud:, jwt:)
        decoded_jwt = Canvas::Security.decode_jwt(jwt)
        new(aud: aud, sub: decoded_jwt[:sub], jwt: jwt)
      rescue Canvas::Security::TokenExpired => e
        raise InvalidTokenError, 'token has expired', e.backtrace
      rescue StandardError => e
        raise InvalidTokenError, e
      end

      def initialize(aud:, sub:, jwt: nil, reg_key: nil)
        @_jwt = jwt if jwt
        @reg_key = reg_key || (jwt && decoded_jwt['reg_key'])
        @aud = aud
        @sub = sub
      end

      def validate!
        decoded_jwt = Canvas::Security.decode_jwt(jwt)
        check_required_assertions(decoded_jwt.keys)
        raise InvalidTokenError, 'invalid iss' if decoded_jwt['iss'] != ISS
        raise InvalidTokenError, 'invalid aud' unless [*decoded_jwt[:aud]].include?(aud)
        raise InvalidTokenError, 'iat must be in the past' unless Time.zone.at(decoded_jwt['iat']) < Time.zone.now
        true
      rescue InvalidTokenError
        raise
      rescue Canvas::Security::TokenExpired => e
        raise InvalidTokenError, 'token has expired', e.backtrace
      rescue StandardError => e
        raise InvalidTokenError, e
      end

      def to_s
        jwt
      end

      private

      def decoded_jwt
        @_decoded_jwt ||= Canvas::Security.decode_jwt(jwt)
      end

      def jwt
        @_jwt ||= begin
          body = {
            iss: ISS,
            sub: sub,
            exp: Setting.get('lti.oauth2.access_token.exp', 1.hour).to_i.seconds.from_now,
            aud: aud,
            iat: Time.zone.now.to_i,
            nbf: Setting.get('lti.oauth2.access_token.nbf', 30.seconds).to_i.seconds.ago,
            jti: SecureRandom.uuid
          }
          body[:reg_key] = @reg_key if @reg_key
          Canvas::Security.create_jwt(body)
        end
      end

      def check_required_assertions(assertion_keys)
        missing_assertions = (%w(iss sub exp aud iat nbf jti) - assertion_keys)
        if missing_assertions.present?
          raise InvalidTokenError, "the following assertions are missing: #{missing_assertions.join(',')}"
        end
      end

    end
  end
end
