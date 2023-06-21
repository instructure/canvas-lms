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
describe Mutations::DeleteInternalSetting do
  let(:internal_setting) { Setting.create!(name: "setting_to_be_deleted", value: "😭") }
  let(:secret_internal_setting) { Setting.create!(name: "secret_setting_to_be_deleted", value: "supersecret", secret: true) }
  let(:sender) { site_admin_user }

  def execute(setting: internal_setting, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        deleteInternalSetting(input: {
          internalSettingId: "#{CanvasSchema.id_from_object(setting, Types::InternalSettingType, nil)}"
        }) {
          internalSettingId
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

  it "destroys the internal setting and returns id" do
    expect(Setting.find_by(id: internal_setting.id)).not_to be_nil
    result = execute
    expect(result["errors"]).to be_nil
    expect(result.dig("data", "deleteInternalSetting", "errors")).to be_nil
    expect(result.dig("data", "deleteInternalSetting", "internalSettingId")).to eq CanvasSchema.id_from_object(internal_setting, Types::InternalSettingType, nil)
    expect(Setting.find_by(id: internal_setting.id)).to be_nil
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "deleteInternalSetting", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    context "the setting doesn't exist" do
      it "fails with not found" do
        result = execute(setting: Setting.new)
        expect_error(result, "not found")
      end
    end

    context "the setting is marked as secret" do
      it "fails with insufficient permissions" do
        result = execute(setting: secret_internal_setting)
        expect_error(result, "insufficient permission")
      end
    end

    context "user does not have manage_internal_settings permission" do
      it "fails with insufficient permissions" do
        result = execute(user_executing: account_admin_user)
        expect_error(result, "insufficient permission")
      end
    end
  end
end
