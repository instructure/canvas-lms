# frozen_string_literal: true

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

describe Login::LoginBrandConfigFilter do
  describe ".filter" do
    subject { described_class.filter(variable_schema) }

    let(:variable_schema) do
      [
        {
          "group_key" => "login",
          "variables" => [
            { "variable_name" => "ic-brand-Login-logo" },
            { "variable_name" => "ic-brand-Login-body-bgd-image" },
            { "variable_name" => "ic-brand-Login-body-bgd-color" },
            { "variable_name" => "ic-brand-Login-footer" } # should be removed
          ]
        },
        {
          "group_key" => "another_group",
          "variables" => [
            { "variable_name" => "ic-brand-Another-variable" }
          ]
        }
      ]
    end

    it "removes variables not in the allowed list" do
      filtered_schema = subject
      login_group = filtered_schema.find { |group| group["group_key"] == "login" }
      expect(login_group["variables"].pluck("variable_name")).to match_array(Login::LoginBrandConfigFilter::ALLOWED_LOGIN_VARS)
    end

    it "does not remove variables in other groups" do
      filtered_schema = subject
      other_group = filtered_schema.find { |group| group["group_key"] == "another_group" }
      expect(other_group["variables"].pluck("variable_name")).to include("ic-brand-Another-variable")
    end

    it "sets the default value for ic-brand-Login-logo to an empty string" do
      filtered_schema = subject
      login_group = filtered_schema.find { |group| group["group_key"] == "login" }
      logo_variable = login_group["variables"].find { |v| v["variable_name"] == "ic-brand-Login-logo" }
      expect(logo_variable).to include("default")
      expect(logo_variable["default"]).to eq("")
    end
  end
end
