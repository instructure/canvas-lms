# frozen_string_literal: true

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
  module OAuth2
    class AccessToken
      private_class_method :new

      ISS = "Canvas"

      attr_reader :aud, :sub, :reg_key, :shard_id

      def self.create_jwt(aud:, sub:, reg_key: nil)
        new(aud:, sub:, reg_key:, shard_id: Shard.current.id)
      end

      def self.from_jwt(aud:, jwt:)
        decoded_jwt = Canvas::Security.decode_jwt(jwt)
        new(aud:, sub: decoded_jwt[:sub], jwt:, shard_id: decoded_jwt[:shard_id])
      rescue Canvas::Security::TokenExpired => e
        raise InvalidTokenError, "token has expired", e.backtrace
      rescue => e
        raise InvalidTokenError, e
      end

      def initialize(aud:, sub:, jwt: nil, reg_key: nil, shard_id: nil)
        @_jwt = jwt if jwt
        @reg_key = reg_key || (jwt && decoded_jwt["reg_key"])
        @aud = aud
        @sub = sub
        @shard_id = shard_id
      end

      def validate!
        decoded_jwt = Canvas::Security.decode_jwt(jwt)
        check_required_assertions(decoded_jwt.keys)
        raise InvalidTokenError, "invalid iss" if decoded_jwt["iss"] != ISS
        raise InvalidTokenError, "invalid aud" unless [*decoded_jwt[:aud]].include?(aud)
        raise InvalidTokenError, "iat must be in the past" unless Time.zone.at(decoded_jwt["iat"]) < Time.zone.now

        true
      rescue InvalidTokenError
        raise
      rescue Canvas::Security::TokenExpired => e
        raise InvalidTokenError, "token has expired", e.backtrace
      rescue => e
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
            sub:,
            exp: 1.hour.from_now,
            aud:,
            iat: Time.zone.now.to_i,
            nbf: 30.seconds.ago,
            jti: SecureRandom.uuid,
            shard_id:
          }
          body[:reg_key] = @reg_key if @reg_key
          Canvas::Security.create_jwt(body)
        end
      end

      def check_required_assertions(assertion_keys)
        missing_assertions = (%w[iss sub exp aud iat nbf jti] - assertion_keys)
        if missing_assertions.present?
          raise InvalidTokenError, "the following assertions are missing: #{missing_assertions.join(",")}"
        end
      end
    end
  end
end
