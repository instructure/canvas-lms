# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe DataFixup::Lti::AddUserUuidCustomVariableToInternalTools do
  let_once(:account) { Account.default }
  let_once(:developer_key) { lti_developer_key_model(account:) }
  let_once(:tool_configuration) do
    lti_tool_configuration_model(developer_key:, lti_registration: developer_key.lti_registration)
  end

  describe ".run" do
    context "sistemic test" do
      before do
        tool_configuration.update!(target_link_uri: "https://sistemic.example.com")
      end

      it "adds the custom field to matching tool configurations using the target link uri" do
        described_class.run
        tool_configuration.reload
        expect(tool_configuration.custom_fields["UserUUID"]).to eq("$vnd.instructure.User.uuid")
      end

      it "does not update tool configurations that do not match the target link uri" do
        tool_configuration.update!(target_link_uri: "https://sistemicc.example.com")
        described_class.run
        expect(tool_configuration.reload.custom_fields["UserUUID"]).to be_nil
      end
    end

    context "sistemic production" do
      before do
        tool_configuration.update!(target_link_uri: "https://sistemic-iad-prod.example.com")
      end

      it "adds the custom field to matching tool configurations using the target link uri" do
        described_class.run
        tool_configuration.reload
        expect(tool_configuration.custom_fields["UserUUID"]).to eq("$vnd.instructure.User.uuid")
      end

      it "does not update tool configurations that do not match the target link uri" do
        tool_configuration.update!(target_link_uri: "https://sistemicc-iad-prod.example.com")
        described_class.run
        expect(tool_configuration.reload.custom_fields["UserUUID"]).to be_nil
      end
    end

    context "impact" do
      before do
        tool_configuration.update!(target_link_uri: "https://example.eesysoft.com")
      end

      it "adds the custom field to matching tool configurations using the target link uri" do
        described_class.run
        expect(tool_configuration.reload.custom_fields["canvas_user_uuid"]).to eq("$vnd.instructure.User.uuid")
      end

      it "does not update tool configurations that do not match the target link uri" do
        tool_configuration.update!(target_link_uri: "https://eesysoft.example.com")
        described_class.run
        expect(tool_configuration.reload.custom_fields["canvas_user_uuid"]).to be_nil
      end
    end
  end

  describe ".update_tool_config" do
    before do
      tool_configuration.update!(target_link_uri: "https://example.target.link.com")
    end

    context "when no matching developer keys exist" do
      it "does not update any tool configurations" do
        expect { described_class.update_tool_config(".example", "custom_field") }
          .not_to change { tool_configuration.reload.custom_fields }
      end
    end

    context "when developer keys exist but are not active" do
      before do
        developer_key.update!(workflow_state: "deleted")
      end

      it "does not update tool configurations" do
        described_class.update_tool_config("target.", "custom_field")
        expect(tool_configuration.reload.custom_fields["custom_field"]).to be_nil
      end
    end

    context "when developer keys exist and are active" do
      it "adds the custom field if it does not already exist" do
        described_class.update_tool_config("target.", "custom_field")
        expect(tool_configuration.reload.custom_fields["custom_field"]).to eq("$vnd.instructure.User.uuid")
      end

      it "does not overwrite the custom field if it already exists" do
        tool_configuration.custom_fields["custom_field"] = "existing_value"
        tool_configuration.save!
        described_class.update_tool_config("target.", "custom_field")
        expect(tool_configuration.reload.custom_fields["custom_field"]).to eq("existing_value")
      end
    end
  end
end
