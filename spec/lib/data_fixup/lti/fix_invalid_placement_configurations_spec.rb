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
#
require "lti_1_3_tool_configuration_spec_helper"

RSpec.describe DataFixup::Lti::FixInvalidPlacementConfigurations do
  subject { described_class.run }

  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:account) { Account.default }
  let(:developer_key) { DeveloperKey.create!(account:, workflow_state: "active", is_lti_key: true, public_jwk:) }

  before do
    tool_configuration.configuration["extensions"].first["settings"]["placements"] = []
    tool_configuration.save!
  end

  def placement_config(tool_config, placement_name)
    tool_config
      .configuration["extensions"]
      .find { |e| e["platform"] == Lti::ToolConfiguration::CANVAS_EXTENSION_LABEL }["settings"]["placements"]
      .find { |p| p["placement"] == placement_name }
  end

  def add_placement(tool_config, placement)
    tool_config.configuration["extensions"].first["settings"]["placements"] << placement
  end

  it "doesn't change the config of a properly configured tool" do
    add_placement(tool_configuration, { placement: "course_navigation", message_type: "LtiResourceLinkRequest" })
    expect { subject }.not_to change { tool_configuration.configuration }
  end

  context "placements that only support deep linking requests" do
    (Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE["LtiDeepLinkingRequest"] - Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE["LtiResourceLinkRequest"]).each do |placement|
      it "swaps the message_type for a misconfigured #{placement} placement" do
        add_placement(tool_configuration, { placement: placement.to_s, message_type: "LtiResourceLinkRequest" })
        # Have to avoid the validation that would prevent this from saving
        tool_configuration.save(validate: false)
        expect { subject }
          .to change { placement_config(tool_configuration.reload, placement.to_s)["message_type"] }
          .from("LtiResourceLinkRequest")
          .to("LtiDeepLinkingRequest")
      end
    end
  end

  context "placements that only support resource link requests" do
    (Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE["LtiResourceLinkRequest"] - Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE["LtiDeepLinkingRequest"]).each do |placement|
      it "swaps the message_type for a misconfigured #{placement} placement" do
        add_placement(tool_configuration, { placement: placement.to_s, message_type: "LtiDeepLinkingRequest" })
        # Have to avoid the validation that would prevent this from saving
        tool_configuration.save(validate: false)
        expect { subject }
          .to change { placement_config(tool_configuration.reload, placement.to_s)["message_type"] }
          .from("LtiDeepLinkingRequest")
          .to("LtiResourceLinkRequest")
      end
    end
  end

  it "avoids placements that don't have a message type" do
    add_placement(tool_configuration, { placement: "course_navigation" })
    tool_configuration.save(validate: false)
    expect { subject }.not_to change { tool_configuration.configuration }
  end

  it "avoids tools that have an invalid placement" do
    add_placement(tool_configuration, { placement: "invalid_placement", message_type: "LtiDeepLinkingRequest" })
    tool_configuration.save(validate: false)
    expect { subject }.not_to change { tool_configuration.configuration }
  end

  it "avoids tools that have an invalid message type" do
    add_placement(tool_configuration, { placement: "course_navigation", message_type: "invalid_message_type" })
    tool_configuration.save(validate: false)
    expect { subject }.not_to change { tool_configuration.configuration }
  end

  it "skips developer keys that were created by Dynamic Registration" do
    dyn_reg = lti_ims_registration_model(account:)

    expect { subject }.not_to change { dyn_reg.reload.configuration }
  end
end
