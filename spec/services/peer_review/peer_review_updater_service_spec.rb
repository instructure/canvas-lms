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

require "spec_helper"

RSpec.describe PeerReview::PeerReviewUpdaterService do
  let(:course) { course_model(name: "Course with Assignment") }
  let(:parent_assignment) do
    assignment_model(
      course:,
      title: "Parent Assignment",
      points_possible: 10,
      grading_type: "points",
      due_at: 1.week.from_now,
      unlock_at: 1.day.from_now,
      lock_at: 2.weeks.from_now,
      peer_review_count: 2,
      peer_reviews: true,
      submission_types: "online_text_entry,online_upload"
    )
  end

  let!(:existing_peer_review_sub_assignment) do
    PeerReviewSubAssignment.create!(
      parent_assignment:,
      context: course,
      title: "Test Peer Review",
      points_possible: 10,
      grading_type: "points"
    )
  end

  let(:updated_points_possible) { 15 }
  let(:updated_grading_type) { "letter_grade" }
  let(:updated_due_at) { 3.days.from_now }
  let(:updated_unlock_at) { 2.days.from_now }
  let(:updated_lock_at) { 1.week.from_now }

  let(:service) do
    described_class.new(
      parent_assignment:,
      points_possible: updated_points_possible,
      grading_type: updated_grading_type,
      due_at: updated_due_at,
      unlock_at: updated_unlock_at,
      lock_at: updated_lock_at
    )
  end

  let(:service_with_all_attributes_due_at) { 5.days.from_now }
  let(:service_with_all_attributes_unlock_at) { 4.days.from_now }
  let(:service_with_all_attributes_lock_at) { 10.days.from_now }

  let(:service_with_all_attributes) do
    described_class.new(
      parent_assignment:,
      points_possible: 20,
      grading_type: "points",
      due_at: service_with_all_attributes_due_at,
      unlock_at: service_with_all_attributes_unlock_at,
      lock_at: service_with_all_attributes_lock_at
    )
  end

  before do
    course.enable_feature!(:peer_review_grading)
  end

  describe "#initialize" do
    it "sets the instance variables correctly" do
      expect(service.instance_variable_get(:@parent_assignment)).to eq(parent_assignment)
      expect(service.instance_variable_get(:@points_possible)).to eq(updated_points_possible)
      expect(service.instance_variable_get(:@grading_type)).to eq(updated_grading_type)
      expect(service.instance_variable_get(:@due_at)).to eq(updated_due_at)
      expect(service.instance_variable_get(:@unlock_at)).to eq(updated_unlock_at)
      expect(service.instance_variable_get(:@lock_at)).to eq(updated_lock_at)
    end

    it "allows nil values for optional parameters" do
      simple_service = described_class.new(parent_assignment:)
      expect(simple_service.instance_variable_get(:@parent_assignment)).to eq(parent_assignment)
      expect(simple_service.instance_variable_get(:@points_possible)).to be_nil
      expect(simple_service.instance_variable_get(:@grading_type)).to be_nil
      expect(simple_service.instance_variable_get(:@due_at)).to be_nil
      expect(simple_service.instance_variable_get(:@unlock_at)).to be_nil
      expect(simple_service.instance_variable_get(:@lock_at)).to be_nil
    end
  end

  describe "#call" do
    before do
      allow(PeerReviewSubAssignment).to receive(:clear_cache_keys)
      allow(SubmissionLifecycleManager).to receive(:recompute)
    end

    context "with valid inputs and existing peer review sub assignment" do
      it "successfully updates the peer review sub assignment" do
        result = service.call

        expect(result).to eq(existing_peer_review_sub_assignment)
        expect(result.points_possible).to eq(updated_points_possible)
        expect(result.grading_type).to eq(updated_grading_type)
        expect(result.due_at).to eq(updated_due_at)
        expect(result.unlock_at).to eq(updated_unlock_at)
        expect(result.lock_at).to eq(updated_lock_at)
      end

      it "saves the peer review sub assignment" do
        expect(existing_peer_review_sub_assignment).to receive(:save!)
        service.call
      end

      it "recomputes due dates after updating the sub assignment" do
        expect(PeerReviewSubAssignment).to receive(:clear_cache_keys)
          .with(existing_peer_review_sub_assignment, :availability)
        expect(SubmissionLifecycleManager).to receive(:recompute)
          .with(existing_peer_review_sub_assignment, update_grades: true, create_sub_assignment_submissions: false)

        service.call
      end

      it "returns the updated peer review sub assignment" do
        result = service.call
        expect(result).to be_a(PeerReviewSubAssignment)
        expect(result.id).to eq(existing_peer_review_sub_assignment.id)
      end

      it "updates all provided attributes on the peer review sub assignment" do
        result = service_with_all_attributes.call

        expect(result.points_possible).to eq(20)
        expect(result.grading_type).to eq("points")
        expect(result.due_at.to_i).to eq(service_with_all_attributes_due_at.to_i)
        expect(result.unlock_at.to_i).to eq(service_with_all_attributes_unlock_at.to_i)
        expect(result.lock_at.to_i).to eq(service_with_all_attributes_lock_at.to_i)
      end

      it "maintains inherited attributes from parent assignment" do
        result = service_with_all_attributes.call

        expect(result.context_id).to eq(parent_assignment.context_id)
        expect(result.assignment_group_id).to eq(parent_assignment.assignment_group_id)
        expect(result.parent_assignment_id).to eq(parent_assignment.id)
        expect(result.title).to include("Peer Review")
      end

      it "updates the title when parent assignment title changes" do
        parent_assignment.update!(title: "Updated Parent Assignment")

        result = service.call

        expect(result.title).to eq("Updated Parent Assignment Peer Review")
      end

      it "updates title even when peer review sub assignment has incorrect title" do
        existing_peer_review_sub_assignment.update!(title: "Wrong Title")

        result = service.call

        expect(result.title).to eq("Parent Assignment Peer Review")
      end

      it "updates group_category_id when parent assignment group_category_id changes" do
        group_category = course.group_categories.create!(name: "Test Group Category")
        parent_assignment.update!(group_category_id: group_category.id)

        result = service.call

        expect(result.group_category_id).to eq(group_category.id)
      end
    end

    context "with partial updates" do
      let(:partial_service) do
        described_class.new(
          parent_assignment:,
          points_possible: updated_points_possible
        )
      end

      it "updates only the provided attributes" do
        original_grading_type = existing_peer_review_sub_assignment.grading_type
        original_due_at = existing_peer_review_sub_assignment.due_at

        result = partial_service.call

        expect(result.points_possible).to eq(updated_points_possible)
        expect(result.grading_type).to eq(original_grading_type)
        expect(result.due_at).to eq(original_due_at)
      end
    end

    context "when validations fail" do
      it "raises error when parent assignment is nil" do
        service.instance_variable_set(:@parent_assignment, nil)
        expect { service.call }.to raise_error(
          PeerReview::InvalidParentAssignmentError,
          "Invalid parent assignment"
        )
      end

      it "raises error when parent assignment is not persisted" do
        new_assignment = Assignment.new(context: course, title: "New Assignment")
        service.instance_variable_set(:@parent_assignment, new_assignment)
        expect { service.call }.to raise_error(
          PeerReview::InvalidParentAssignmentError,
          "Invalid parent assignment"
        )
      end

      it "raises error when parent assignment is external tool assignment" do
        external_tool_assignment = assignment_model(
          course:,
          title: "External Tool Assignment",
          submission_types: "external_tool"
        )
        service.instance_variable_set(:@parent_assignment, external_tool_assignment)

        expect { service.call }.to raise_error(
          PeerReview::InvalidAssignmentSubmissionTypesError,
          "Peer reviews cannot be used with External Tool assignments"
        )
      end

      it "raises error when parent assignment is discussion topic assignment" do
        discussion_topic_assignment = assignment_model(
          course:,
          title: "Discussion Topic Assignment",
          submission_types: "discussion_topic"
        )
        service.instance_variable_set(:@parent_assignment, discussion_topic_assignment)

        expect { service.call }.to raise_error(
          PeerReview::InvalidAssignmentSubmissionTypesError,
          "Peer reviews cannot be used with Discussion Topic assignments"
        )
      end

      it "raises error when feature is disabled" do
        course.disable_feature!(:peer_review_grading)
        expect { service.call }.to raise_error(
          PeerReview::FeatureDisabledError,
          "Peer Review Grading feature flag is disabled"
        )
      end

      it "raises error when peer review sub assignment does not exist" do
        existing_peer_review_sub_assignment.destroy!
        parent_assignment.reload

        service_without_sub_assignment = described_class.new(
          parent_assignment:,
          points_possible: updated_points_possible
        )

        expect { service_without_sub_assignment.call }.to raise_error(
          PeerReview::SubAssignmentNotExistError,
          "Peer review sub assignment does not exist"
        )
      end
    end
  end

  describe "#run_validations" do
    it "calls all required validation methods" do
      expect(service).to receive(:validate_parent_assignment)
      expect(service).to receive(:validate_assignment_submission_types)
      expect(service).to receive(:validate_feature_enabled)
      expect(service).to receive(:validate_peer_review_sub_assignment_exists)

      service.send(:run_validations)
    end
  end

  describe "#update_peer_review_sub_assignment" do
    context "with all update parameters" do
      it "updates all provided attributes on the peer review sub assignment" do
        result = service.send(:update_peer_review_sub_assignment)

        expect(result).to eq(existing_peer_review_sub_assignment)
        expect(result.points_possible).to eq(updated_points_possible)
        expect(result.grading_type).to eq(updated_grading_type)
        expect(result.due_at).to eq(updated_due_at)
        expect(result.unlock_at).to eq(updated_unlock_at)
        expect(result.lock_at).to eq(updated_lock_at)
      end

      it "suspends due date caching during updates" do
        expect(AbstractAssignment).to receive(:suspend_due_date_caching).and_yield
        service.send(:update_peer_review_sub_assignment)
      end

      it "returns the peer review sub assignment" do
        result = service.send(:update_peer_review_sub_assignment)
        expect(result).to be_a(PeerReviewSubAssignment)
        expect(result.id).to eq(existing_peer_review_sub_assignment.id)
      end
    end

    context "with partial update parameters" do
      let(:partial_service) do
        described_class.new(
          parent_assignment:,
          points_possible: updated_points_possible,
          grading_type: updated_grading_type
        )
      end

      it "updates only the provided attributes" do
        original_due_at = existing_peer_review_sub_assignment.due_at
        original_unlock_at = existing_peer_review_sub_assignment.unlock_at
        original_lock_at = existing_peer_review_sub_assignment.lock_at

        result = partial_service.send(:update_peer_review_sub_assignment)

        expect(result.points_possible).to eq(updated_points_possible)
        expect(result.grading_type).to eq(updated_grading_type)
        expect(result.due_at).to eq(original_due_at)
        expect(result.unlock_at).to eq(original_unlock_at)
        expect(result.lock_at).to eq(original_lock_at)
      end

      it "suspends due date caching when attributes are updated" do
        expect(AbstractAssignment).to receive(:suspend_due_date_caching).and_yield
        partial_service.send(:update_peer_review_sub_assignment)
      end
    end

    context "with no update parameters" do
      let(:no_update_service) { described_class.new(parent_assignment:) }

      it "syncs inherited attributes from parent and returns the peer review sub assignment" do
        result = no_update_service.send(:update_peer_review_sub_assignment)

        expect(result).to eq(existing_peer_review_sub_assignment)
        expect(result.description).to eq(parent_assignment.description)
        expect(result.peer_review_count).to eq(parent_assignment.peer_review_count)
        expect(result.peer_reviews).to eq(parent_assignment.peer_reviews)
        expect(result.submission_types).to eq("online_text_entry")
      end

      it "suspends due date caching when inherited attributes are synced" do
        expect(AbstractAssignment).to receive(:suspend_due_date_caching).and_yield
        no_update_service.send(:update_peer_review_sub_assignment)
      end
    end
  end
end
