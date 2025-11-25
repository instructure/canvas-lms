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

RSpec.describe PeerReview::PeerReviewCreatorService do
  include PeerReviewHelpers

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
      automatic_peer_reviews: true,
      anonymous_peer_reviews: false,
      intra_group_peer_reviews: true,
      submission_types: "online_text_entry,online_upload"
    )
  end

  let(:peer_review_grading_type) { "points" }
  let(:peer_review_points_possible) { 15 }

  let(:service) do
    described_class.new(
      parent_assignment:,
      points_possible: peer_review_points_possible,
      grading_type: peer_review_grading_type
    )
  end

  before do
    course.enable_feature!(:peer_review_allocation_and_grading)
  end

  describe "#initialize" do
    it "inherits from PeerReviewCommonService" do
      expect(described_class.superclass).to eq(PeerReview::PeerReviewCommonService)
    end

    it "accepts the same parameters as the parent class" do
      expect { service }.not_to raise_error
    end

    it "can be initialized with minimal parameters" do
      minimal_service = described_class.new(parent_assignment:)
      expect(minimal_service).to be_a(described_class)
    end
  end

  describe "#call" do
    context "when all validations pass" do
      it "creates successfully PeerReviewSubAssignment" do
        expect { service.call }.to change(PeerReviewSubAssignment, :count).by(1)
      end

      it "returns the created PeerReviewSubAssignment" do
        result = service.call
        expect(result).to be_a(PeerReviewSubAssignment)
        expect(result).to be_persisted
      end

      it "sets the correct parent_assignment_id" do
        result = service.call
        expect(result.parent_assignment_id).to eq(parent_assignment.id)
      end

      it "sets the correct title with peer review count" do
        result = service.call
        expect(result.title).to eq(expected_peer_review_title(parent_assignment.title, parent_assignment.peer_review_count))
      end

      it "sets the custom points_possible when provided" do
        result = service.call
        expect(result.points_possible).to eq(peer_review_points_possible)
      end

      it "sets the custom grading_type when provided" do
        result = service.call
        expect(result.grading_type).to eq(peer_review_grading_type)
      end

      it "inherits context from parent assignment" do
        result = service.call
        expect(result.context_id).to eq(parent_assignment.context_id)
        expect(result.context_type).to eq(parent_assignment.context_type)
      end

      it "sets has_sub_assignments to false" do
        result = service.call
        expect(result.has_sub_assignments).to be(false)
      end

      it "inherits peer review settings from parent" do
        result = service.call
        expect(result.peer_reviews).to eq(parent_assignment.peer_reviews)
        expect(result.peer_review_count).to eq(parent_assignment.peer_review_count)
        expect(result.anonymous_peer_reviews).to eq(parent_assignment.anonymous_peer_reviews)
        expect(result.automatic_peer_reviews).to eq(parent_assignment.automatic_peer_reviews)
        expect(result.intra_group_peer_reviews).to eq(parent_assignment.intra_group_peer_reviews)
      end

      it "inherits peer_review_submission_required and peer_review_across_sections from parent" do
        parent_assignment.update!(
          peer_review_submission_required: true,
          peer_review_across_sections: false
        )

        result = service.call
        expect(result.peer_review_submission_required).to be true
        expect(result.peer_review_across_sections).to be false
      end

      it "inherits group_category_id from parent" do
        group_category = course.group_categories.create!(name: "Test Group Category")
        parent_assignment.update!(group_category_id: group_category.id)

        result = service.call
        expect(result.group_category_id).to eq(parent_assignment.group_category_id)
      end

      it "recomputes due dates after creating the sub assignment" do
        expect(PeerReviewSubAssignment).to receive(:clear_cache_keys).with(
          an_instance_of(PeerReviewSubAssignment),
          :availability
        )

        original_recompute = SubmissionLifecycleManager.method(:recompute)
        recompute_call_count = 0
        peer_review_sub_assignment_recompute_called = false

        allow(SubmissionLifecycleManager).to receive(:recompute) do |assignment, **options|
          recompute_call_count += 1
          if assignment.is_a?(PeerReviewSubAssignment) &&
             options[:update_grades] == true &&
             options[:create_sub_assignment_submissions] == false
            peer_review_sub_assignment_recompute_called = true
          end
          original_recompute.call(assignment, **options)
        end

        service.call

        expect(peer_review_sub_assignment_recompute_called).to be(true)
        expect(recompute_call_count).to be > 0
      end

      it "links existing assessment requests to the newly created peer review sub assignment" do
        student1 = user_model
        student2 = user_model
        student3 = user_model
        create_enrollment(course, student1, enrollment_state: "active")
        create_enrollment(course, student2, enrollment_state: "active")
        create_enrollment(course, student3, enrollment_state: "active")
        submission1 = submission_model(assignment: parent_assignment, user: student1)
        submission2 = submission_model(assignment: parent_assignment, user: student2)
        submission3 = submission_model(assignment: parent_assignment, user: student3)

        assessment_request1 = AssessmentRequest.create!(
          user: student1,
          asset: submission1,
          assessor_asset: submission2,
          assessor: student2
        )
        assessment_request2 = AssessmentRequest.create!(
          user: student2,
          asset: submission2,
          assessor_asset: submission3,
          assessor: student3
        )

        expect(assessment_request1.peer_review_sub_assignment_id).to be_nil
        expect(assessment_request2.peer_review_sub_assignment_id).to be_nil

        result = service.call

        assessment_request1.reload
        assessment_request2.reload
        expect(assessment_request1.peer_review_sub_assignment_id).to eq(result.id)
        expect(assessment_request2.peer_review_sub_assignment_id).to eq(result.id)
      end

      it "uses custom dates when provided" do
        custom_due_at = 3.days.from_now
        custom_unlock_at = 2.days.from_now
        custom_lock_at = 1.week.from_now

        parent_assignment_with_dates = assignment_model(
          course:,
          title: "Parent Assignment with Custom Dates",
          points_possible: 10,
          grading_type: "points",
          peer_review_count: 2,
          peer_reviews: true
        )

        custom_service = described_class.new(
          parent_assignment: parent_assignment_with_dates,
          due_at: custom_due_at,
          unlock_at: custom_unlock_at,
          lock_at: custom_lock_at
        )
        result = custom_service.call

        expect(result.due_at).to eq(custom_due_at)
        expect(result.unlock_at).to eq(custom_unlock_at)
        expect(result.lock_at).to eq(custom_lock_at)
      end
    end

    context "when validations fail" do
      it "raises error for nil parent assignment" do
        invalid_service = described_class.new(parent_assignment: nil)
        expect { invalid_service.call }.to raise_error(
          PeerReview::InvalidParentAssignmentError,
          "Invalid parent assignment"
        )
      end

      it "raises error for external tool assignment" do
        external_tool_assignment = assignment_model(
          course:,
          title: "External Tool Assignment",
          submission_types: "external_tool"
        )
        invalid_service = described_class.new(parent_assignment: external_tool_assignment)

        expect { invalid_service.call }.to raise_error(
          PeerReview::InvalidAssignmentSubmissionTypesError,
          "Peer reviews cannot be used with External Tool assignments"
        )
      end

      it "raises error for discussion topic assignment" do
        discussion_topic_assignment = assignment_model(
          course:,
          title: "Discussion Topic Assignment",
          submission_types: "discussion_topic"
        )
        invalid_service = described_class.new(parent_assignment: discussion_topic_assignment)

        expect { invalid_service.call }.to raise_error(
          PeerReview::InvalidAssignmentSubmissionTypesError,
          "Peer reviews cannot be used with Discussion Topic assignments"
        )
      end

      it "raises error when feature is disabled" do
        course.disable_feature!(:peer_review_allocation_and_grading)
        expect { service.call }.to raise_error(
          PeerReview::FeatureDisabledError,
          "Peer Review Allocation and Grading feature flag is disabled"
        )
      end

      it "raises error when peer review sub assignment already exists" do
        PeerReviewSubAssignment.create!(parent_assignment:)
        expect { service.call }.to raise_error(
          PeerReview::SubAssignmentExistsError,
          "Peer review sub assignment exists"
        )
      end

      it "does not create PeerReviewSubAssignment" do
        course.disable_feature!(:peer_review_allocation_and_grading)
        expect do
          service.call
        rescue
          nil
        end.not_to change(PeerReviewSubAssignment, :count)
      end
    end

    context "when validating peer review dates against parent assignment" do
      let(:parent_with_boundaries) do
        assignment_model(
          course:,
          title: "Parent with Date Boundaries",
          unlock_at: 2.days.from_now,
          due_at: 1.week.from_now,
          lock_at: 2.weeks.from_now,
          peer_reviews: true
        )
      end

      context "with valid dates" do
        it "creates peer review when dates are within parent boundaries" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            unlock_at: 3.days.from_now,
            due_at: 1.week.from_now,
            lock_at: 10.days.from_now
          )

          expect { service.call }.to change(PeerReviewSubAssignment, :count).by(1)
        end

        it "creates peer review when dates are at exact parent boundaries" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            unlock_at: parent_with_boundaries.unlock_at,
            due_at: 1.week.from_now,
            lock_at: parent_with_boundaries.lock_at
          )

          expect { service.call }.to change(PeerReviewSubAssignment, :count).by(1)
        end

        it "creates peer review with partial dates" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            due_at: 1.week.from_now
          )

          expect { service.call }.to change(PeerReviewSubAssignment, :count).by(1)
        end

        it "creates peer review when no custom dates provided" do
          service = described_class.new(parent_assignment: parent_with_boundaries)

          expect { service.call }.to change(PeerReviewSubAssignment, :count).by(1)
        end
      end

      context "with invalid dates" do
        it "raises InvalidDatesError when unlock_at is before parent unlock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            unlock_at: 1.day.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review unlock date cannot be before assignment unlock date/
          )
        end

        it "raises InvalidDatesError when due_at is before parent unlock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            due_at: 1.day.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review due date cannot be before assignment unlock date/
          )
        end

        it "raises InvalidDatesError when due_at is after parent lock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            due_at: 3.weeks.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review due date cannot be after assignment lock date/
          )
        end

        it "raises InvalidDatesError when lock_at is after parent lock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            lock_at: 3.weeks.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Peer review lock date cannot be after assignment lock date/
          )
        end

        it "raises InvalidDatesError when due_at is before unlock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            unlock_at: 1.week.from_now,
            due_at: 5.days.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Due date cannot be before unlock date/
          )
        end

        it "raises InvalidDatesError when due_at is after lock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            due_at: 1.week.from_now,
            lock_at: 5.days.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Due date cannot be after lock date/
          )
        end

        it "raises InvalidDatesError when unlock_at is after lock_at" do
          service = described_class.new(
            parent_assignment: parent_with_boundaries,
            unlock_at: 1.week.from_now,
            lock_at: 5.days.from_now
          )

          expect { service.call }.to raise_error(
            PeerReview::InvalidDatesError,
            /Unlock date cannot be after lock date/
          )
        end
      end
    end
  end

  describe "#run_validations" do
    it "runs all required validations in order" do
      expect(service).to receive(:validate_parent_assignment).ordered
      expect(service).to receive(:validate_assignment_submission_types).ordered
      expect(service).to receive(:validate_feature_enabled).ordered
      expect(service).to receive(:validate_peer_review_sub_assignment_not_exist).ordered

      service.send(:run_validations)
    end

    it "stops at first validation failure" do
      service.instance_variable_set(:@parent_assignment, nil)

      expect(service).to receive(:validate_parent_assignment).and_call_original
      expect(service).not_to receive(:validate_assignment_submission_types)
      expect(service).not_to receive(:validate_feature_enabled)
      expect(service).not_to receive(:validate_peer_review_sub_assignment_not_exist)

      expect { service.send(:run_validations) }.to raise_error(PeerReview::InvalidParentAssignmentError)
    end
  end

  describe "#create_peer_review_sub_assignment" do
    it "creates a new PeerReviewSubAssignment with correct attributes" do
      expect(PeerReviewSubAssignment).to receive(:new).with(
        hash_including(
          parent_assignment_id: parent_assignment.id,
          context_id: parent_assignment.context_id,
          points_possible: peer_review_points_possible,
          grading_type: peer_review_grading_type
        )
      ).and_call_original

      expect_any_instance_of(PeerReviewSubAssignment).to receive(:save!)

      service.send(:create_peer_review_sub_assignment)
    end

    it "suspends due date caching during creation" do
      expect(AbstractAssignment).to receive(:suspend_due_date_caching).and_yield

      service.send(:create_peer_review_sub_assignment)
    end

    it "returns the created peer review sub assignment" do
      result = service.send(:create_peer_review_sub_assignment)
      expect(result).to be_a(PeerReviewSubAssignment)
      expect(result).to be_persisted
    end
  end

  describe "#compute_due_dates_and_create_submissions" do
    let(:peer_review_sub_assignment) do
      # Create the sub assignment without triggering the compute method
      service.send(:run_validations)
      service.send(:create_peer_review_sub_assignment)
    end

    it "clears cache keys for availability" do
      expect(PeerReviewSubAssignment).to receive(:clear_cache_keys).with(
        peer_review_sub_assignment,
        :availability
      )
      allow(SubmissionLifecycleManager).to receive(:recompute)

      service.send(:compute_due_dates_and_create_submissions, peer_review_sub_assignment)
    end

    it "recomputes submission lifecycle with correct parameters" do
      allow(PeerReviewSubAssignment).to receive(:clear_cache_keys)
      expect(SubmissionLifecycleManager).to receive(:recompute).with(
        peer_review_sub_assignment,
        update_grades: true,
        create_sub_assignment_submissions: false
      )

      service.send(:compute_due_dates_and_create_submissions, peer_review_sub_assignment)
    end
  end

  describe "#link_existing_assessment_requests" do
    let(:peer_review_sub_assignment) do
      # Create the sub assignment without triggering the full service
      service.send(:run_validations)
      service.send(:create_peer_review_sub_assignment)
    end

    it "links existing assessment requests for the parent assignment to the peer review sub assignment" do
      student1 = user_model
      student2 = user_model
      create_enrollment(course, student1, enrollment_state: "active")
      create_enrollment(course, student2, enrollment_state: "active")
      submission1 = submission_model(assignment: parent_assignment, user: student1)
      submission2 = submission_model(assignment: parent_assignment, user: student2)

      assessment_request = AssessmentRequest.create!(
        user: student1,
        asset: submission1,
        assessor_asset: submission2,
        assessor: student2
      )

      expect(assessment_request.peer_review_sub_assignment_id).to be_nil

      service.send(:link_existing_assessment_requests, peer_review_sub_assignment)

      assessment_request.reload
      expect(assessment_request.peer_review_sub_assignment_id).to eq(peer_review_sub_assignment.id)
    end

    it "handles the case when there are no existing assessment requests" do
      expect { service.send(:link_existing_assessment_requests, peer_review_sub_assignment) }.not_to raise_error
    end
  end

  describe "integration with ApplicationService" do
    it "can be called via the class method" do
      expect { described_class.call(parent_assignment:) }.to change(PeerReviewSubAssignment, :count).by(1)
    end

    it "returns the same result whether called via instance or class method" do
      # Create separate parent assignments to avoid unique constraint violation
      parent_assignment_2 = assignment_model(
        course:,
        title: "Parent Assignment 2",
        points_possible: 10,
        grading_type: "points",
        peer_review_count: 2,
        peer_reviews: true
      )

      instance_result = service.call
      class_result = described_class.call(
        parent_assignment: parent_assignment_2,
        points_possible: peer_review_points_possible,
        grading_type: peer_review_grading_type
      )

      expect(instance_result.class).to eq(class_result.class)
      expect(instance_result).to be_a(PeerReviewSubAssignment)
      expect(class_result).to be_a(PeerReviewSubAssignment)
    end
  end

  describe "explicit nil values during creation" do
    let(:assignment) do
      course.assignments.create!(
        title: "Parent Assignment",
        points_possible: 50,
        peer_reviews: true,
        submission_types: "online_text_entry"
      )
    end

    context "when dates are explicitly set to nil" do
      let(:service_with_nil_dates) do
        described_class.new(
          parent_assignment: assignment,
          due_at: nil,
          unlock_at: nil,
          lock_at: nil,
          points_possible: 10
        )
      end

      it "creates peer review without due_at" do
        peer_review_sub = service_with_nil_dates.call
        expect(peer_review_sub.due_at).to be_nil
      end

      it "creates peer review without unlock_at" do
        peer_review_sub = service_with_nil_dates.call
        expect(peer_review_sub.unlock_at).to be_nil
      end

      it "creates peer review without lock_at" do
        peer_review_sub = service_with_nil_dates.call
        expect(peer_review_sub.lock_at).to be_nil
      end

      it "sets other provided attributes" do
        peer_review_sub = service_with_nil_dates.call
        expect(peer_review_sub.points_possible).to eq(10)
      end
    end

    context "when grading_type parameter is explicitly set to nil" do
      let(:service_with_nil_grading_type) do
        described_class.new(
          parent_assignment: assignment,
          grading_type: nil,
          points_possible: 10
        )
      end

      it "creates peer review with default grading type" do
        peer_review_sub = service_with_nil_grading_type.call
        expect(peer_review_sub).to be_persisted
        expect(peer_review_sub.grading_type).not_to be_nil
      end
    end
  end
end
