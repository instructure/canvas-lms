# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require "spec_helper"
require_relative "../graphql_spec_helper"
describe Mutations::UpdateInternalSetting do
  let(:internal_setting) { Setting.create!(name: "setting_to_be_updated", value: "change me") }
  let(:secret_internal_setting) { Setting.create!(name: "secret_setting_to_be_deleted", value: "supersecret", secret: true) }
  let(:sender) { site_admin_user }

  def execute(value, setting: internal_setting, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        updateInternalSetting(input: {
          internalSettingId: "#{CanvasSchema.id_from_object(setting, Types::InternalSettingType, nil)}",
          value: "#{value}"
        }) {
          internalSetting {
            id
            name
            value
            secret
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
    context = { current_user: user_executing, request: ActionDispatch::TestRequest.create }
    CanvasSchema.execute(mutation_command, context:)
  end

  it "updates and returns the internal setting" do
    expect(Setting.find_by(id: internal_setting.id)).not_to be_nil

    result = execute("new_value")
    expect(result["errors"]).to be_nil

    internal_setting_result = result.dig("data", "updateInternalSetting", "internalSetting")
    expect(internal_setting_result["errors"]).to be_nil
    expect(internal_setting_result["id"]).to eq CanvasSchema.id_from_object(internal_setting, Types::InternalSettingType, nil)
    expect(internal_setting_result["name"]).to eq internal_setting.name
    expect(internal_setting_result["value"]).to eq "new_value"
    expect(internal_setting_result["secret"]).to be false

    expect(Setting.find(internal_setting.id).value).to eq "new_value"
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "updateInternalSetting", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    context "the setting doesn't exist" do
      it "fails with not found" do
        result = execute("new_value", setting: Setting.new)
        expect_error(result, "not found")
      end
    end

    context "the setting is marked as secret" do
      it "fails with insufficient permissions" do
        result = execute("new_value", setting: secret_internal_setting)
        expect_error(result, "insufficient permission")
      end
    end

    context "user does not have manage_internal_settings permission" do
      it "fails with insufficient permissions" do
        result = execute("new_value", user_executing: account_admin_user)
        expect_error(result, "insufficient permission")
      end
    end
  end
end
