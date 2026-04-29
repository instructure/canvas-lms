# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../../lti_1_3_tool_configuration_spec_helper"

RSpec.describe DataFixup::CleanLtiToolConfigurations do
  include_context "lti_1_3_tool_configuration_spec_helper"

  let_once(:root_account) { account_model }
  let_once(:developer_key) { lti_registration.developer_key }
  let_once(:lti_registration) { lti_registration_with_tool(account: root_account) }
  let_once(:tool_configuration) { lti_registration.manual_configuration }

  def execute_fixup
    fixup = described_class.new
    fixup.run
    run_jobs
  end

  describe "#run" do
    it "cleans string dimension values to integers in launch_settings" do
      tool_configuration.update_column(:launch_settings, {
                                         "selection_height" => "800",
                                         "selection_width" => "600"
                                       })

      execute_fixup

      expect(tool_configuration.reload.launch_settings["selection_height"]).to eq(800)
      expect(tool_configuration.launch_settings["selection_width"]).to eq(600)
    end

    it "cleans non-string custom_fields values to strings" do
      tool_configuration.update_column(:custom_fields, {
                                         "number_field" => 123,
                                         "bool_field" => true
                                       })

      execute_fixup

      expect(tool_configuration.reload.custom_fields["number_field"]).to eq("123")
      expect(tool_configuration.custom_fields["bool_field"]).to eq("true")
    end

    it "cleans invalid privacy_level to default" do
      tool_configuration.update_column(:privacy_level, "PRIVATE")

      execute_fixup

      expect(tool_configuration.reload.privacy_level).to eq("anonymous")
    end

    it "cleans invalid 'default' settings in placements" do
      tool_configuration.update_column(
        :placements,
        tool_configuration.placements.tap do |p|
          p.first["default"] = true
        end
      )

      execute_fixup

      expect(tool_configuration.reload.placements.first["default"]).to eql("enabled")
    end

    it "does not save a record that does not need changes" do
      expect { execute_fixup }.not_to change { tool_configuration.reload.updated_at }
    end

    it "handles multiple records, some valid, some not" do
      invalid = lti_registration_with_tool(account: root_account).manual_configuration

      invalid.update_column(:privacy_level, "PRIVATE")
      invalid.update_column(:public_jwk, [])
      invalid.update_column(:custom_fields, { "numeric" => "123", "boolean" => true })

      expect do
        execute_fixup
      end.not_to change { tool_configuration.reload.updated_at }

      expect(invalid.reload.custom_fields["numeric"]).to eq("123")
      expect(invalid.custom_fields).to eql({ "numeric" => "123", "boolean" => "true" })
    end
  end
end
