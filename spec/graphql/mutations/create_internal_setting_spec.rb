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
describe Mutations::CreateInternalSetting do
  let(:sender) { site_admin_user }

  def execute(name, value, user_executing: sender)
    mutation_command = <<~GQL
      mutation {
        createInternalSetting(input: {
          name: "#{name}"
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

  it "creates and returns the internal setting" do
    expect(Setting.find_by(name: "sentry_disabled")).to be_nil

    result = execute("sentry_disabled", "never! 👀")
    expect(result["errors"]).to be_nil

    internal_setting_result = result.dig("data", "createInternalSetting", "internalSetting")
    expect(internal_setting_result["errors"]).to be_nil
    expect(internal_setting_result["id"]).to eq CanvasSchema.id_from_object(Setting.find_by(name: "sentry_disabled"), Types::InternalSettingType, nil)
    expect(internal_setting_result["name"]).to eq "sentry_disabled"
    expect(internal_setting_result["value"]).to eq "never! 👀"
    expect(internal_setting_result["secret"]).to be false

    Setting.reset_cache!
    expect(Setting.get("sentry_disabled", "")).to eq "never! 👀"
  end

  context "errors" do
    def expect_error(result, message)
      errors = result["errors"] || result.dig("data", "createInternalSetting", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    context "user does not have manage_internal_settings permission" do
      it "fails with insufficient permissions" do
        result = execute("sentry_disabled", "never! 👀", user_executing: account_admin_user)
        expect_error(result, "insufficient permission")
      end
    end
  end
end
