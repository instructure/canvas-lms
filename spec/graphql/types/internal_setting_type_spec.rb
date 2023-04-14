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
#

require_relative "../graphql_spec_helper"

describe Types::InternalSettingType do
  let(:setting) { Setting.create!(name: "test_setting", value: "test_value") }
  let(:secret_setting) { Setting.create!(name: "secret_setting", value: "ooh, secret!", secret: true) }

  it "returns the correct values" do
    type = GraphQLTypeTester.new(setting, current_user: site_admin_user)

    expect(type.resolve("_id")).to eq setting.id.to_s
    expect(type.resolve("name")).to eq "test_setting"
    expect(type.resolve("value")).to eq "test_value"
    expect(type.resolve("secret")).to be false
  end

  context "when the setting is marked as secret" do
    it "returns a null value" do
      type = GraphQLTypeTester.new(secret_setting, current_user: site_admin_user)

      expect(type.resolve("_id")).to eq secret_setting.id.to_s
      expect(type.resolve("name")).to eq "secret_setting"
      expect(type.resolve("value")).to be_nil
      expect(type.resolve("secret")).to be true
    end
  end

  context "when the user does not have manage_internal_settings permission" do
    it "does not return data" do
      type = GraphQLTypeTester.new(secret_setting, current_user: account_admin_user)

      expect(type.resolve("_id")).to be_nil
    end
  end
end
