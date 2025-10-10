# frozen_string_literal: true

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

RSpec.describe DataFixup::Lti::BackfillContextExternalToolRegistrationIds do
  subject { described_class.run }

  let(:account) { Account.default }
  let(:developer_key) { DeveloperKey.create!(account:) }
  let(:developer_key_with_registration) { registration.developer_key }
  let(:registration) { lti_registration_with_tool(account:) }
  let(:eligible_tool) { registration.deployments.first }

  describe ".run" do
    it "backfills lti_registration_id for 1.3 tools with developer keys that have registration ids" do
      eligible_tool.update_column(:lti_registration_id, nil)

      expect { subject }.to change { eligible_tool.reload.lti_registration_id }
        .from(nil).to(registration.id)
    end

    it "does not update 1.1 tools" do
      tool = ContextExternalTool.create!(
        context: account,
        name: "Test Tool",
        url: "https://example.com",
        consumer_key: "key",
        shared_secret: "secret",
        lti_version: "1.1",
        developer_key: developer_key_with_registration
      )

      expect { subject }.not_to change { tool.reload.lti_registration_id }
    end

    it "does not update tools with developer keys that have no registration id" do
      tool = ContextExternalTool.create!(
        context: account,
        name: "Test Tool",
        url: "https://example.com",
        consumer_key: "key",
        shared_secret: "secret",
        lti_version: "1.3",
        developer_key:,
        lti_registration_id: nil
      )

      expect { subject }.not_to change { tool.reload.lti_registration_id }
    end

    it "does not update deleted tools" do
      tool = ContextExternalTool.create!(
        context: account,
        name: "Test Tool",
        url: "https://example.com",
        consumer_key: "key",
        shared_secret: "secret",
        lti_version: "1.3",
        developer_key: developer_key_with_registration,
        workflow_state: "deleted"
      )
      tool.update_column(:lti_registration_id, nil)

      expect { subject }.not_to change { tool.reload.lti_registration_id }
    end

    it "does not update 1.3 tools that already have a registration id" do
      expect { subject }.not_to change { eligible_tool.reload.lti_registration_id }
    end

    it "does not update tools without a developer key" do
      tool = ContextExternalTool.create!(
        context: account,
        name: "Test Tool",
        url: "https://example.com",
        consumer_key: "key",
        shared_secret: "secret",
        lti_version: "1.3"
      )

      expect { subject }.not_to change { tool.reload.lti_registration_id }
    end

    it "updates multiple qualifying tools in a single query" do
      tool1 = ContextExternalTool.create!(
        context: account,
        name: "Test Tool 1",
        url: "https://example.com",
        consumer_key: "key1",
        shared_secret: "secret1",
        lti_version: "1.3",
        developer_key: developer_key_with_registration,
        lti_registration_id: nil
      )

      tool2 = ContextExternalTool.create!(
        context: account,
        name: "Test Tool 2",
        url: "https://example.com",
        consumer_key: "key2",
        shared_secret: "secret2",
        lti_version: "1.3",
        developer_key: developer_key_with_registration,
        lti_registration_id: nil
      )

      tool3 = ContextExternalTool.create!(
        context: account,
        name: "Test Tool 3",
        url: "https://example.com",
        consumer_key: "key3",
        shared_secret: "secret3",
        lti_version: "1.1"
      )

      expect { subject }.to change { tool1.reload.lti_registration_id }
        .from(nil).to(registration.id)
        .and change { tool2.reload.lti_registration_id }
        .from(nil).to(registration.id)
      expect(tool3.reload.lti_registration_id).to be_nil
    end
  end
end
