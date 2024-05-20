# frozen_string_literal: true

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
    REQUIRED_ASSERTIONS = Set.new(%w[sub aud exp iat jti])

    validate :assertions, :aud, :exp, :iat, :jti

    def initialize(jwt:, expected_aud:, override_sub: nil, full_errors: false, require_iss: false, skip_jti_check: false, max_iat_age: nil)
      @jwt = OpenStruct.new jwt
      @assertions = Set.new(jwt.keys)
      @expected_aud = expected_aud
      @full_errors = full_errors
      @require_iss = require_iss
      @jwt.sub = override_sub if override_sub.present?
      @skip_jti_check = skip_jti_check
      @max_iat_age = max_iat_age || 5.minutes
    end

    def error_message
      errors.full_messages.join(" | ")
    end

    private

    def errors?
      @full_errors ? false : !errors.empty?
    end

    def assertions
      missing_assertions = (REQUIRED_ASSERTIONS - @assertions)
      missing_assertions << "iss" if @require_iss && @assertions.delete?("iss").nil?
      unless missing_assertions.empty?
        errors.add(:base, "the following assertions are missing: #{missing_assertions.to_a.join(",")}")
        @full_errors = false
      end
    end

    def aud
      return if errors?
      return if Array(@jwt.aud).intersect?(Array(@expected_aud))

      errors.add(:base, "the 'aud' is invalid")
    end

    def exp
      errors.add(:base, "the 'exp' must be a number") if @jwt.exp.present? && !@jwt.exp.is_a?(Numeric)
      return if errors?

      exp_time = Time.zone.at(@jwt.exp)
      errors.add(:base, "the JWT has expired") if exp_time < Time.zone.now
    end

    def iat
      errors.add(:base, "the 'iat' must be a number") if @jwt.iat.present? && !@jwt.iat.is_a?(Numeric)
      return if errors?

      iat_time = Time.zone.at(@jwt.iat)
      iat_future_buffer = 30.seconds
      errors.add(:base, "the 'iat' must be less than #{@max_iat_age} seconds old") if iat_time < @max_iat_age.ago
      errors.add(:base, "the 'iat' must not be in the future") if iat_time > Time.zone.now + iat_future_buffer
    end

    def jti
      return if errors? || @skip_jti_check

      nonce_duration = (@jwt.exp.to_i - @jwt.iat.to_i).seconds
      nonce_key = "nonce:#{@jwt.sub}:#{@jwt.jti}"
      unless Lti::Security.check_and_store_nonce(nonce_key, @jwt.iat, nonce_duration)
        errors.add(:base, "the 'jti' is invalid")
      end
    end
  end
end
