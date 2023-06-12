# frozen_string_literal: true

# Copyright (C) 2018 - present Instructure, Inc.
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

describe QuizzesNext::Service do
  describe ".enabled_in_context?" do
    let(:root_account) { double "root_account", feature_allowed?: true }
    let(:context) { double("context", root_account:) }

    context "when the feature is enabled on the context" do
      it "will return true" do
        allow(context).to receive(:feature_enabled?).and_return(true)
        expect(described_class.enabled_in_context?(context)).to be(true)
      end
    end

    context "when the feature is not enabled on the context but allowed on root account" do
      it "will return true" do
        allow(context).to receive(:feature_enabled?).and_return(false)
        expect(described_class.enabled_in_context?(context)).to be(true)
      end
    end

    context "when feature is not enabled in course and root account" do
      it "will return false" do
        allow(context).to receive(:feature_enabled?).and_return(false)
        allow(context.root_account).to receive(:feature_allowed?).and_return(false)
        expect(described_class.enabled_in_context?(context)).to be(false)
      end
    end
  end

  describe ".active_lti_assignments_for_course" do
    it "returns active lti assignments in the course" do
      course = course_model
      lti_assignment_active1 = assignment_model(course:, submission_types: "external_tool")
      lti_assignment_active2 = assignment_model(course:, submission_types: "external_tool")
      lti_assignment_inactive = assignment_model(course:, submission_types: "external_tool")
      assignment_active = assignment_model(course:, submission_types: "external_tool")

      lti_assignment_inactive.destroy
      tool = course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      lti_assignment_active1.external_tool_tag_attributes = { content: tool }
      lti_assignment_active1.save!
      lti_assignment_active2.external_tool_tag_attributes = { content: tool }
      lti_assignment_active2.save!

      active_lti_assignments = described_class.active_lti_assignments_for_course(course)

      expect(active_lti_assignments).to include(lti_assignment_active1)
      expect(active_lti_assignments).to include(lti_assignment_active2)
      expect(active_lti_assignments).not_to include(lti_assignment_inactive)
      expect(active_lti_assignments).not_to include(assignment_active)

      filtered_assignments = described_class.active_lti_assignments_for_course(course,
                                                                               selected_assignment_ids: [lti_assignment_active2.id, assignment_active.id])
      expect(filtered_assignments).to eq [lti_assignment_active2]
    end
  end

  describe ".assignment_not_in_export?" do
    it "returns true for anything except assignment not found" do
      assignment_hash = { "$canvas_assignment_id": "1234" }
      assignment_not_found = { "$canvas_assignment_id": Canvas::Migration::ExternalContent::Translator::NOT_FOUND }

      expect(described_class.assignment_not_in_export?(assignment_hash)).to be(false)
      expect(described_class.assignment_not_in_export?(assignment_not_found)).to be(true)
    end
  end

  describe ".assignment_duplicated?" do
    it "returns true if assignment has data suggesting it is duplicated" do
      assignment_hash = { original_assignment_id: "1234" }
      expect(described_class.assignment_duplicated?(assignment_hash)).to be_truthy
    end

    it "returns false if assignment does not have data suggesting it is duplicated" do
      assignment_hash = {}
      expect(described_class.assignment_duplicated?(assignment_hash)).to be_falsey
    end
  end
end
