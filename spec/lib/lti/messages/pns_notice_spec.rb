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

describe Lti::Messages::PnsNotice do
  subject { pns_notice.to_cached_hash[:post_payload] }

  let(:context) { course_model }
  let(:expander) { nil }
  let(:user) { student_in_course(course: context).user }
  let(:opts) { { custom_params: { myparam: "$Canvas.account.id" } } }
  let(:tool) { external_tool_1_3_model(context:, opts: { settings: { custom_fields: { tool_custom: "123" } } }) }
  let(:notice) { { id: "hello", timestamp: "time", type: "LtiHelloWorldNotice" }.with_indifferent_access }

  let(:pns_notice) do
    Lti::Messages::PnsNotice.new(
      tool:,
      context:,
      user:,
      expander:,
      notice:,
      opts:
    )
  end

  it "includes notice claim" do
    expect(subject["#{IMS_CLAIM_PREFIX}/notice"]).to eq(notice)
  end

  it "does not include placement claim" do
    expect(subject.keys).not_to include("#{INST_CLAIM_PREFIX}/placement")
  end

  it "only includes certain base claims" do
    expect(subject.keys).to include(
      "#{IMS_CLAIM_PREFIX}/deployment_id",
      "#{IMS_CLAIM_PREFIX}/context"
    )
  end

  context "with variable expander" do
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

    it "includes custom params claim" do
      expect(subject["#{IMS_CLAIM_PREFIX}/custom"]).to eq({ myparam: Account.default.id.to_s, tool_custom: "123" }.with_indifferent_access)
    end
  end

  context "with extra_claims" do
    let(:opts) { { extra_claims: [:target_link_uri] } }

    it "also includes given base claims" do
      expect(subject.keys).to include("#{IMS_CLAIM_PREFIX}/target_link_uri")
    end
  end
end
