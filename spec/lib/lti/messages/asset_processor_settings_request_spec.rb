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

IMS_CLAIM_PREFIX = "https://purl.imsglobal.org/spec/lti/claim"
INST_CLAIM_PREFIX = "https://canvas.instructure.com"

describe Lti::Messages::AssetProcessorSettingsRequest do
  subject { asset_processor_settings_request.to_cached_hash[:post_payload] }

  let(:context) { course_model }
  let(:expander) do
    Lti::VariableExpander.new(
      context.root_account,
      context,
      nil,
      {
        current_user: user,
        tool:
      }
    )
  end
  let(:user) { student_in_course(course: context).user }
  let(:opts) { {} }
  let(:return_url) { nil }
  let(:tool) { external_tool_1_3_model(context:) }
  let(:asset_processor) { lti_asset_processor_model }

  let(:asset_processor_settings_request) do
    Lti::Messages::AssetProcessorSettingsRequest.new(
      tool:,
      context:,
      user:,
      expander:,
      return_url:,
      asset_processor:,
      opts:
    )
  end

  it "includes message_type claim" do
    expect(subject["#{IMS_CLAIM_PREFIX}/message_type"]).to eq("LtiAssetProcessorSettingsRequest")
  end

  it "includes activity claim" do
    expect(subject["#{IMS_CLAIM_PREFIX}/activity"]["id"]).to eq(asset_processor.assignment.lti_context_id)
    expect(subject["#{IMS_CLAIM_PREFIX}/activity"]["title"]).to eq(asset_processor.assignment.title)
  end

  it "includes certain base claims" do
    expect(subject.keys).to include(
      "#{IMS_CLAIM_PREFIX}/deployment_id",
      "#{IMS_CLAIM_PREFIX}/context",
      "#{IMS_CLAIM_PREFIX}/target_link_uri",
      "#{IMS_CLAIM_PREFIX}/version",
      "#{IMS_CLAIM_PREFIX}/roles"
    )
  end

  it "includes custom params claim" do
    expect(subject["#{IMS_CLAIM_PREFIX}/custom"]).to eq({
                                                          "customkey" => "customvar",
                                                          "raid" => asset_processor.root_account_id.to_s
                                                        })
  end

  context "when asset_processor is null" do
    let(:asset_processor) { nil }

    it "message is invalid" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
