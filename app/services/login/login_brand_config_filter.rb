# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# this filter is temporary and should be removed once the features/new_login UI
# is fully adopted and old/unused login brand config variables are no longer needed
class Login::LoginBrandConfigFilter
  ALLOWED_LOGIN_VARS = %w[
    ic-brand-Login-logo
    ic-brand-Login-body-bgd-image
    ic-brand-Login-body-bgd-color
  ].freeze

  def self.filter(variable_schema)
    variable_schema.each do |group|
      next unless group["group_key"] == "login"

      # remove disallowed login-related brand variables
      group["variables"].reject! do |variable|
        variable_name = variable["variable_name"]
        variable_name.start_with?("ic-brand-Login") && !ALLOWED_LOGIN_VARS.include?(variable_name)
      end

      # set default to "" for login logo to prevent legacy image from displaying
      # this preserves the key to satisfy frontend prop type expectations
      group["variables"].each do |variable|
        if variable["variable_name"] == "ic-brand-Login-logo"
          variable["default"] = ""
        end
      end
    end

    variable_schema
  end
end
