#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas::Security
  class JwtValidator
    include ActiveModel::Validations
    REQUIRED_ASSERTIONS = Set.new(%w(sub aud exp iat jti))

    validate :assertions, :aud, :exp, :iat, :jti

    def initialize(jwt:, expected_aud:, override_sub: nil, full_errors: false, require_iss: false)
      @jwt = OpenStruct.new jwt
      @assertions = Set.new(jwt.keys)
      @expected_aud = expected_aud
      @full_errors = full_errors
      @require_iss = require_iss
      @jwt.sub = override_sub if override_sub.present?
    end

    def error_message
      errors.full_messages.join(' | ')
    end

    private

    def errors?
      @full_errors ? false : !errors.empty?
    end

    def assertions
      missing_assertions = (REQUIRED_ASSERTIONS - @assertions)
      missing_assertions << 'iss' if @require_iss && @assertions.delete?('iss').nil?
      unless missing_assertions.empty?
        errors.add(:base, "the following assertions are missing: #{missing_assertions.to_a.join(',')}")
        @full_errors = false
      end
    end

    def aud
      return if errors?
      msg = "the 'aud' must be the LTI Authorization endpoint"
      if @jwt.aud.is_a? String
        errors.add(:base, msg) if @jwt.aud != @expected_aud
      elsif @jwt.aud.exclude? @expected_aud
        errors.add(:base, msg)
      end
    end

    def exp
      return if errors?
      exp_time = Time.zone.at(@jwt.exp)
      errors.add(:base, "the JWT has expired") if exp_time < Time.zone.now
    end

    def iat
      return if errors?
      iat_time = Time.zone.at(@jwt.iat)
      max_iat_age = Setting.get("oauth2_jwt_iat_ago_in_seconds", 5.minutes.to_s).to_i.seconds
      errors.add(:base, "the 'iat' must be less than #{max_iat_age} seconds old") if iat_time < max_iat_age.ago
      errors.add(:base, "the 'iat' must not be in the future") if iat_time > Time.zone.now
    end

    def jti
      return if errors?
      nonce_duration = (@jwt.exp.to_i - @jwt.iat.to_i).seconds
      nonce_key = "nonce:#{@jwt.sub}:#{@jwt.jti}"
      unless Lti::Security.check_and_store_nonce(nonce_key, @jwt.iat, nonce_duration)
        errors.add(:base, "the 'jti' is invalid")
      end
    end
  end
end
