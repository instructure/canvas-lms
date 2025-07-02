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

require_relative "../graphql_spec_helper"

describe Types::LtiAssetProcessorType do
  let_once(:course) { course_factory(active_all: true) }
  let_once(:teacher) { teacher_in_course(active_all: true, course:).user }
  let_once(:student) { student_in_course(course:, active_all: true).user }

  let_once(:admin_user) { account_admin_user_with_role_changes }
  before(:once) do
    @assignment = course.assignments.create(title: "some assignment",
                                            points_possible: 10,
                                            submission_types: ["online_text_entry"],
                                            workflow_state: "published",
                                            allowed_extensions: %w[doc xlt foo])
    @ap1 = lti_asset_processor_model(assignment: @assignment, title: "ap1")
    @ap2 = lti_asset_processor_model(assignment: @assignment, title: "ap2")
    @ap3 = lti_asset_processor_model(assignment: @assignment, title: "ap2", workflow_state: "deleted")
    @assignment_type = GraphQLTypeTester.new(@assignment, current_user: teacher)
  end

  def ap_query(field)
    query = "ltiAssetProcessorsConnection { nodes { #{field} } }"
    @assignment_type.resolve(query)
  end

  let(:ap_titles) { ap_query("title") }

  it "is accessible through assignments ltiAssetProcessorsConnection" do
    expect(ap_titles).to match_array(["ap1", "ap2"])
  end

  it "returns fields for all the fields needed in Speedgrader" do
    @ap1.update(
      text: "ap1 text",
      icon: { "url" => "https://example.com/ap1.png" }
    )

    @ap2.update! icon: nil
    t = @ap2.context_external_tool
    t.name = "ap2 tool name"
    t.settings["ActivityAssetProcessor"]["icon_url"] = "https://example.com/ap2_tool.png"
    t.settings["ActivityAssetProcessor"]["text"] = "ap2 tool placement text"
    t.save!

    fields = {
      :_id => [@ap1, @ap2].map { it.id.to_s },
      :title => ["ap1", "ap2"],
      :text => ["ap1 text", @ap2.text],
      :iconOrToolIconUrl => [
        "https://example.com/ap1.png", "https://example.com/ap2_tool.png"
      ],
      "externalTool { _id }" => [@ap1, @ap2].map { it.context_external_tool_id.to_s },
      "externalTool { name }" => [@ap1.context_external_tool.name, "ap2 tool name"],
      "externalTool { labelFor(placement: ActivityAssetProcessor) }" => [
        @ap1.context_external_tool.label_for("ActivityAssetProcessor"),
        "ap2 tool placement text"
      ]
    }

    fields.each do |key, vals|
      arr = ap_query(key)
      expect(arr).to be_a(Array)
      expect(arr.length).to eq(2)
      expect(arr).to match_array(vals)
    end
  end

  context "when the lti_asset_processor FF is off" do
    before { @assignment.root_account.enable_feature!(:lti_asset_processor) }
    before { @assignment.root_account.disable_feature!(:lti_asset_processor) }

    it { expect(ap_titles).to be_nil }
  end
end
