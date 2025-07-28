# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  module PasswordPolicyAccountSettingValidator
    INTEGER_REGEX = /\A[+-]?\d+\z/

    def valid_integer?(str)
      # "123" ==> true | "-123" ==> true | "12.3" ==> false | "abc" ==> false
      INTEGER_REGEX.match?(str)
    end

    def validate_password_policy_for(setting, setting_value)
      if valid_integer?(setting_value)
        validate_setting(setting, setting_value)
      else
        errors.add(setting, t("An integer value is required"))
      end
    end

    private

    def validate_setting(setting, setting_value)
      validate_for_negative_value(setting, setting_value)

      case setting
      when "minimum_character_length"
        validate_character_length(setting,
                                  setting_value,
                                  Canvas::Security::PasswordPolicy::MIN_CHARACTER_LENGTH,
                                  Canvas::Security::PasswordPolicy::MAX_CHARACTER_LENGTH)
      when "maximum_login_attempts"
        validate_login_attempts(setting,
                                setting_value,
                                Canvas::Security::PasswordPolicy::MIN_LOGIN_ATTEMPTS,
                                Canvas::Security::PasswordPolicy::MAX_LOGIN_ATTEMPTS)
      end
    end

    def validate_for_negative_value(setting, setting_value)
      errors.add(setting, t("Value must be positive")) if setting_value.to_i < 0
    end

    def validate_character_length(setting, setting_value, min_length, max_length)
      if setting_value.to_i < min_length.to_i
        errors.add(setting, t("Must be at least %{min_length} or greater", min_length:))
      elsif setting_value.to_i > max_length.to_i
        errors.add(setting, t("Must not exceed %{max_length}", max_length:))
      end
    end

    def validate_login_attempts(setting, setting_value, min_attempts, max_attempts)
      if setting_value.to_i < min_attempts.to_i
        errors.add(setting, t("Must be at least %{min_attempts} or greater", min_attempts:))
      elsif setting_value.to_i > max_attempts.to_i
        errors.add(setting, t("Must not exceed %{max_attempts}", max_attempts:))
      end
    end
  end
end
