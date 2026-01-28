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

require "spec_helper"

RSpec.describe PeerReviewSubAssignment do
  describe "associations" do
    it "belongs to a parent assignment" do
      association = PeerReviewSubAssignment.reflect_on_association(:parent_assignment)
      expect(association.macro).to eq :belongs_to
      expect(association.class_name).to eq "Assignment"
      expect(association.inverse_of.name).to eq :peer_review_sub_assignment
    end

    it "has many assessment_requests" do
      association = PeerReviewSubAssignment.reflect_on_association(:assessment_requests)
      expect(association.macro).to eq :has_many
    end
  end

  describe "validations" do
    let(:course) { course_model(name: "Course with Assignment") }
    let(:parent_assignment) { assignment_model(course:, title: "Parent Assignment") }

    it "is not valid without a parent_assignment_id" do
      peer_review_sub_assignment = PeerReviewSubAssignment.new
      expect(peer_review_sub_assignment).not_to be_valid
      expect(peer_review_sub_assignment.errors[:parent_assignment_id]).to include("can't be blank")
    end

    describe "parent_assignment_id uniqueness" do
      it "is not valid with a duplicate parent_assignment_id" do
        PeerReviewSubAssignment.create!(parent_assignment:)
        duplicate_peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:)
        expect(duplicate_peer_review_sub_assignment).not_to be_valid
        expect(duplicate_peer_review_sub_assignment.errors[:parent_assignment_id]).to include("has already been taken")
      end

      it "allows duplicate parent_assignment_id for deleted records" do
        first = PeerReviewSubAssignment.create!(parent_assignment:)
        first.destroy
        duplicate_peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:)
        expect(duplicate_peer_review_sub_assignment).to be_valid
      end
    end

    it "is not valid if has_sub_assignments is true" do
      peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, has_sub_assignments: true)
      expect(peer_review_sub_assignment).not_to be_valid
      expect(peer_review_sub_assignment.errors[:has_sub_assignments]).to include(I18n.t("cannot have sub assignments"))
    end

    it "is not valid with a sub_assignment_tag" do
      peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, sub_assignment_tag: "some_tag")
      expect(peer_review_sub_assignment).not_to be_valid
      expect(peer_review_sub_assignment.errors[:sub_assignment_tag]).to include(I18n.t("cannot have sub assignment tag"))
    end

    describe "#context_matches_parent_assignment" do
      let(:other_course) { Course.create! }

      it "is valid when context matches parent assignment context" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:)
        expect(peer_review_sub_assignment).to be_valid
      end

      it "is invalid when context does not match parent assignment context" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: other_course)
        expect(peer_review_sub_assignment).not_to be_valid
        expect(peer_review_sub_assignment.errors[:context]).to include("must match parent assignment context")
      end
    end

    describe "#set_default_context" do
      it "sets context to parent assignment's context when context is nil" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:)
        expect(peer_review_sub_assignment.context).to eq(parent_assignment.context)
      end

      it "does not override explicitely provided context" do
        other_course = Course.create!
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: other_course)
        expect(peer_review_sub_assignment.context).to eq(other_course)
      end

      it "handles nil parent_assignment gracefully" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new
        expect(peer_review_sub_assignment.context).to be_nil
      end
    end

    describe "#context_explicitly_provided?" do
      it "returns true when context is explicitly provided" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:, context: course)
        expect(peer_review_sub_assignment.send(:context_explicitly_provided?)).to be true
      end

      it "returns false when context is auto-set from parent assignment" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:)
        expect(peer_review_sub_assignment.send(:context_explicitly_provided?)).to be false
      end

      it "returns false when no context and no parent assignment" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new
        expect(peer_review_sub_assignment.send(:context_explicitly_provided?)).to be false
      end
    end

    describe "#parent_assignment_not_discussion_topic_or_external_tool" do
      it "is not valid when parent assignment is a discussion topic" do
        discussion_topic_assignment = assignment_model(course:, title: "Discussion Topic Assignment", submission_types: "discussion_topic")
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment: discussion_topic_assignment)
        expect(peer_review_sub_assignment).not_to be_valid
        expect(peer_review_sub_assignment.errors[:parent_assignment]).to include(I18n.t("cannot be a discussion topic"))
      end

      it "is not valid when parent assignment is an external tool" do
        external_tool_assignment = assignment_model(course:, title: "External Tool Assignment", submission_types: "external_tool")
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment: external_tool_assignment)
        expect(peer_review_sub_assignment).not_to be_valid
        expect(peer_review_sub_assignment.errors[:parent_assignment]).to include(I18n.t("cannot be an external tool"))
      end

      it "is valid when parent assignment is not a discussion topic or external tool" do
        regular_assignment = assignment_model(course:, title: "Regular Assignment", submission_types: "online_text_entry")
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment: regular_assignment)
        expect(peer_review_sub_assignment).to be_valid
      end
    end

    describe "#points_possible_changes_ok?" do
      let(:peer_review_sub_assignment) do
        PeerReviewSubAssignment.create!(
          parent_assignment:,
          points_possible: 10
        )
      end
      let(:student) { user_model }
      let(:assessor) { user_model }
      let(:student_submission) { submission_model(assignment: parent_assignment, user: student) }
      let(:assessor_submission) { submission_model(assignment: parent_assignment, user: assessor) }

      before do
        parent_assignment.update!(peer_reviews: true)
        course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "allows changes when peer_review_allocation_and_grading feature is disabled" do
        course.disable_feature!(:peer_review_allocation_and_grading)
        AssessmentRequest.create!(
          user: student,
          asset: student_submission,
          assessor_asset: assessor_submission,
          assessor:,
          workflow_state: "completed"
        )

        peer_review_sub_assignment.points_possible = 20
        expect(peer_review_sub_assignment).to be_valid
      end

      it "allows changes when peer_reviews is disabled" do
        parent_assignment.update!(peer_reviews: false)
        AssessmentRequest.create!(
          user: student,
          asset: student_submission,
          assessor_asset: assessor_submission,
          assessor:,
          workflow_state: "completed"
        )

        peer_review_sub_assignment.points_possible = 20
        expect(peer_review_sub_assignment).to be_valid
      end

      it "allows changes when no peer review submissions exist" do
        peer_review_sub_assignment.points_possible = 20
        expect(peer_review_sub_assignment).to be_valid
      end

      it "prevents changes when peer review submissions exist" do
        AssessmentRequest.create!(
          user: student,
          asset: student_submission,
          assessor_asset: assessor_submission,
          assessor:,
          workflow_state: "completed"
        )

        peer_review_sub_assignment.points_possible = 20
        expect(peer_review_sub_assignment).not_to be_valid
        expect(peer_review_sub_assignment.errors[:points_possible]).to include(
          I18n.t("Students have already submitted peer reviews, so reviews required and points cannot be changed.")
        )
      end

      it "allows creating a new record with points_possible set" do
        AssessmentRequest.create!(
          user: student,
          asset: student_submission,
          assessor_asset: assessor_submission,
          assessor:,
          workflow_state: "completed"
        )

        new_peer_review_sub = PeerReviewSubAssignment.new(
          parent_assignment:,
          points_possible: 100
        )
        expect(new_peer_review_sub).to be_valid
      end

      it "allows deletion even when peer review submissions exist" do
        AssessmentRequest.create!(
          user: student,
          asset: student_submission,
          assessor_asset: assessor_submission,
          assessor:,
          workflow_state: "completed"
        )

        peer_review_sub_assignment.destroy
        expect(peer_review_sub_assignment.workflow_state).to eq("deleted")
      end
    end

    describe "#sync_submission_types_with_grading_type" do
      it "sets submission_types to 'peer_review' when grading_type is 'points'" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(
          parent_assignment:,
          grading_type: "points"
        )
        # .valid? triggers the before_validation callback without persisting to database
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)
      end

      it "sets submission_types to 'not_graded' when grading_type is 'not_graded'" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(
          parent_assignment:,
          grading_type: "not_graded"
        )
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq("not_graded")
      end

      it "auto-corrects invalid submission_types to 'peer_review' based on grading_type" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(
          parent_assignment:,
          submission_types: "online_text_entry",
          grading_type: "points"
        )
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)
      end

      it "auto-corrects invalid submission_types to 'not_graded' based on grading_type" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(
          parent_assignment:,
          submission_types: "online_upload",
          grading_type: "not_graded"
        )
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq("not_graded")
      end

      it "updates submission_types when grading_type changes to 'not_graded'" do
        peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          parent_assignment:,
          grading_type: "points"
        )
        expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)

        peer_review_sub_assignment.grading_type = "not_graded"
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq("not_graded")
      end

      it "updates submission_types when grading_type changes from 'not_graded' to 'points'" do
        peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          parent_assignment:,
          grading_type: "not_graded"
        )
        expect(peer_review_sub_assignment.submission_types).to eq("not_graded")

        peer_review_sub_assignment.grading_type = "points"
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)
      end

      it "defaults to 'peer_review' when grading_type is not specified" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(parent_assignment:)
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)
      end

      it "overrides manually set submission_types with value based on grading_type" do
        peer_review_sub_assignment = PeerReviewSubAssignment.new(
          parent_assignment:,
          submission_types: "external_tool",
          grading_type: "points"
        )
        peer_review_sub_assignment.valid?
        expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)
      end

      it "handles all grading types correctly" do
        %w[points percent letter_grade gpa_scale pass_fail].each do |grading_type|
          peer_review_sub_assignment = PeerReviewSubAssignment.new(
            parent_assignment:,
            grading_type:
          )
          peer_review_sub_assignment.valid?
          expect(peer_review_sub_assignment.submission_types).to eq(PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE)
        end
      end
    end
  end

  describe "#checkpoint?" do
    it "returns false" do
      expect(subject.checkpoint?).to be(false)
    end
  end

  describe "#checkpoints_parent?" do
    it "returns false" do
      expect(subject.checkpoints_parent?).to be(false)
    end
  end

  describe "#governs_submittable?" do
    it "returns false" do
      expect(subject.governs_submittable?).to be(false)
    end
  end

  describe "#effective_group_category_id" do
    let(:course) { course_model(name: "Course with Assignment") }
    let(:parent_assignment) { assignment_model(course:, title: "Parent Assignment") }
    let(:group_category) { course.group_categories.create!(name: "Test Group Category") }

    it "returns the group_category_id when set" do
      peer_review_sub_assignment = PeerReviewSubAssignment.create!(
        parent_assignment:,
        group_category_id: group_category.id
      )
      expect(peer_review_sub_assignment.effective_group_category_id).to eq(group_category.id)
    end

    it "returns nil when group_category_id is not set" do
      peer_review_sub_assignment = PeerReviewSubAssignment.create!(parent_assignment:)
      expect(peer_review_sub_assignment.effective_group_category_id).to be_nil
    end

    it "returns nil when group_category_id is explicitly set to nil" do
      peer_review_sub_assignment = PeerReviewSubAssignment.create!(
        parent_assignment:,
        group_category_id: nil
      )
      expect(peer_review_sub_assignment.effective_group_category_id).to be_nil
    end
  end

  describe "#soft_deleted?" do
    let(:course) { course_model(name: "Course with Assignment") }
    let(:parent_assignment) { assignment_model(course:, title: "Parent Assignment") }
    let(:peer_review_sub_assignment) { PeerReviewSubAssignment.create!(parent_assignment:) }

    it "returns true when workflow_state changes to deleted" do
      peer_review_sub_assignment.update!(workflow_state: "deleted")
      expect(peer_review_sub_assignment.send(:soft_deleted?)).to be(true)
    end

    it "returns false when workflow_state changes to something other than deleted" do
      peer_review_sub_assignment.update!(workflow_state: "published")
      expect(peer_review_sub_assignment.send(:soft_deleted?)).to be(false)
    end

    it "returns false when workflow_state is deleted but no change occurred" do
      peer_review_sub_assignment.update!(workflow_state: "deleted")
      peer_review_sub_assignment.reload
      expect(peer_review_sub_assignment.send(:soft_deleted?)).to be(false)
    end

    it "returns false when workflow_state was not changed" do
      expect(peer_review_sub_assignment.send(:soft_deleted?)).to be(false)
    end

    it "returns false when workflow_state changes from deleted to another state" do
      peer_review_sub_assignment.update!(workflow_state: "deleted")
      peer_review_sub_assignment.update!(workflow_state: "published")
      expect(peer_review_sub_assignment.send(:soft_deleted?)).to be(false)
    end
  end

  describe "#unlink_assessment_requests" do
    let(:course) { course_model(name: "Course with Assignment") }
    let(:parent_assignment) { assignment_model(course:, title: "Parent Assignment") }
    let(:peer_review_sub_assignment) { PeerReviewSubAssignment.create!(parent_assignment:) }
    let(:user1) { user_model }
    let(:user2) { user_model }
    let(:assessor1) { user_model }
    let(:assessor2) { user_model }
    let(:submission1) { submission_model(assignment: parent_assignment, user: user1) }
    let(:submission2) { submission_model(assignment: parent_assignment, user: user2) }
    let(:assessor_submission1) { submission_model(assignment: parent_assignment, user: assessor1) }
    let(:assessor_submission2) { submission_model(assignment: parent_assignment, user: assessor2) }

    let!(:assessment_request1) do
      AssessmentRequest.create!(
        user: user1,
        asset: submission1,
        assessor_asset: assessor_submission1,
        assessor: assessor1,
        peer_review_sub_assignment:
      )
    end

    let!(:assessment_request2) do
      AssessmentRequest.create!(
        user: user2,
        asset: submission2,
        assessor_asset: assessor_submission2,
        assessor: assessor2,
        peer_review_sub_assignment:
      )
    end

    context "when called directly" do
      it "sets peer_review_sub_assignment_id to nil for all associated assessment requests" do
        expect(assessment_request1.peer_review_sub_assignment_id).to eq(peer_review_sub_assignment.id)
        expect(assessment_request2.peer_review_sub_assignment_id).to eq(peer_review_sub_assignment.id)

        peer_review_sub_assignment.send(:unlink_assessment_requests)

        assessment_request1.reload
        assessment_request2.reload
        expect(assessment_request1.peer_review_sub_assignment_id).to be_nil
        expect(assessment_request2.peer_review_sub_assignment_id).to be_nil
      end

      it "does not affect assessment requests associated with other peer review sub assignments" do
        other_parent_assignment = assignment_model(course:, title: "Other Parent Assignment")
        other_peer_review_sub_assignment = PeerReviewSubAssignment.create!(parent_assignment: other_parent_assignment)
        other_user = user_model
        other_assessor = user_model
        other_submission = submission_model(assignment: other_parent_assignment, user: other_user)
        other_assessor_submission = submission_model(assignment: other_parent_assignment, user: other_assessor)
        other_assessment_request = AssessmentRequest.create!(
          user: other_user,
          asset: other_submission,
          assessor_asset: other_assessor_submission,
          assessor: other_assessor,
          peer_review_sub_assignment: other_peer_review_sub_assignment
        )

        peer_review_sub_assignment.send(:unlink_assessment_requests)

        other_assessment_request.reload
        expect(other_assessment_request.peer_review_sub_assignment_id).to eq(other_peer_review_sub_assignment.id)
      end

      it "handles the case when there are no associated assessment requests" do
        parent_assignment = assignment_model(course:, title: "Assignment Without Assigned Peer Reviews")
        peer_review_sub_without_associated_assessment_requests = PeerReviewSubAssignment.create!(parent_assignment:)

        expect do
          peer_review_sub_without_associated_assessment_requests.send(:unlink_assessment_requests)
        end.not_to raise_error
      end

      it "does not delete the assessment requests, only unlinks them" do
        initial_count = AssessmentRequest.count

        peer_review_sub_assignment.send(:unlink_assessment_requests)

        expect(AssessmentRequest.count).to eq(initial_count)
        expect(AssessmentRequest.find(assessment_request1.id)).to be_present
        expect(AssessmentRequest.find(assessment_request2.id)).to be_present
      end

      it "uses update_all for bulk update" do
        expect(peer_review_sub_assignment.assessment_requests).to receive(:update_all).with(peer_review_sub_assignment_id: nil)

        peer_review_sub_assignment.send(:unlink_assessment_requests)
      end
    end

    context "when triggered by after_save callback" do
      it "is called automatically when the peer review sub assignment is soft deleted" do
        expect(peer_review_sub_assignment).to receive(:unlink_assessment_requests)

        peer_review_sub_assignment.destroy
      end

      it "is not called when the peer review sub assignment is saved but not soft deleted" do
        expect(peer_review_sub_assignment).not_to receive(:unlink_assessment_requests)

        peer_review_sub_assignment.update!(title: "Updated Title")
      end

      it "is not called when the workflow_state changes to something other than deleted" do
        expect(peer_review_sub_assignment).not_to receive(:unlink_assessment_requests)

        peer_review_sub_assignment.update!(workflow_state: "published")
      end
    end
  end

  describe "delete behavior" do
    let(:course) { course_model(name: "Course with Assignment") }
    let(:parent_assignment) { assignment_model(course:, title: "Parent Assignment") }
    let(:peer_review_sub_assignment) { PeerReviewSubAssignment.create!(parent_assignment:) }
    let(:user) { user_model }
    let(:assessor) { user_model }
    let(:submission) { submission_model(assignment: parent_assignment, user:) }
    let(:assessor_submission) { submission_model(assignment: parent_assignment, user: assessor) }
    let(:assessment_request) do
      AssessmentRequest.create!(
        user:,
        asset: submission,
        assessor_asset: assessor_submission,
        assessor:,
        peer_review_sub_assignment:
      )
    end

    it "unlinks associated assessment request when soft deleted" do
      expect(assessment_request.peer_review_sub_assignment_id).to eq(peer_review_sub_assignment.id)

      peer_review_sub_assignment.destroy

      assessment_request.reload
      expect(assessment_request.peer_review_sub_assignment_id).to be_nil
    end

    it "unlinks associated assessment request when hard deleted" do
      expect(assessment_request.peer_review_sub_assignment_id).to eq(peer_review_sub_assignment.id)

      peer_review_sub_assignment.destroy_permanently!

      assessment_request.reload
      expect(assessment_request.peer_review_sub_assignment_id).to be_nil
    end
  end
end
