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

describe Lti::Messages::EulaRequest do
  subject { eula_request.to_cached_hash[:post_payload] }

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

  let(:eula_request) do
    Lti::Messages::EulaRequest.new(
      tool:,
      context:,
      user:,
      expander:,
      return_url:,
      opts:
    )
  end

  it "includes eulaservice type claim" do
    expect(subject["#{IMS_CLAIM_PREFIX}/eulaservice"]).to eq({
                                                               "url" => tool.asset_processor_eula_url,
                                                               "scope" => [
                                                                 "https://purl.imsglobal.org/spec/lti/scope/eula/user",
                                                                 "https://purl.imsglobal.org/spec/lti/scope/eula/deployment"
                                                               ]
                                                             })
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
    tool.custom_fields = { "field1" => "$Canvas.user.id", "field2" => "$Canvas.user.id" }
    tool.settings["ActivityAssetProcessor"] = {
      "eula" => { "custom_fields" => { "field1" => "$Canvas.user.id" } }
    }
    tool.save!
    expect(subject["#{IMS_CLAIM_PREFIX}/custom"]).to eq({
                                                          "field1" => user.id.to_s,
                                                          "field2" => user.id.to_s,
                                                        })
  end
end
