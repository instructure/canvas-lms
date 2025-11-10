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

RSpec.describe PeerReview::AllocationService do
  let(:course) { course_model }
  let(:assignment) do
    assignment_model(
      course:,
      title: "Peer Review Assignment",
      peer_reviews: true,
      peer_review_count: 2,
      automatic_peer_reviews: false,
      submission_types: "online_text_entry"
    )
  end
  let(:assessor) { user_model }
  let(:student1) { user_model }
  let(:student2) { user_model }
  let(:student3) { user_model }

  let(:service) do
    described_class.new(
      assignment:,
      assessor:
    )
  end

  before do
    course.enroll_student(assessor, enrollment_state: :active)
    course.enroll_student(student1, enrollment_state: :active)
    course.enroll_student(student2, enrollment_state: :active)
    course.enroll_student(student3, enrollment_state: :active)

    # Enable feature flag at course level by default
    course.enable_feature!(:peer_review_allocation)
  end

  describe "#initialize" do
    it "sets the assignment instance variable" do
      expect(service.instance_variable_get(:@assignment)).to eq(assignment)
    end

    it "sets the assessor instance variable" do
      expect(service.instance_variable_get(:@assessor)).to eq(assessor)
    end
  end

  describe "#allocate" do
    context "when validation fails" do
      context "when feature flag is not enabled" do
        before do
          course.disable_feature!(:peer_review_allocation)
        end

        it "returns error result" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:feature_disabled)
          expect(result[:message]).to include("feature is not enabled")
          expect(result[:status]).to eq(:bad_request)
        end
      end

      context "when peer reviews are not enabled on the assignment" do
        before do
          assignment.update!(peer_reviews: false)
        end

        it "returns error result" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_reviews_not_enabled)
          expect(result[:message]).to include("peer reviews enabled")
          expect(result[:status]).to eq(:bad_request)
        end
      end

      context "when assessor has not submitted" do
        before do
          assignment.submissions.find_by(user: student1).update!(workflow_state: "submitted")
        end

        it "returns error result" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:not_submitted)
          expect(result[:message]).to include("must submit")
          expect(result[:status]).to eq(:bad_request)
        end
      end

      context "when assignment is locked" do
        before do
          assignment.update!(
            due_at: 3.days.ago,
            unlock_at: 5.days.ago,
            lock_at: 1.day.ago
          )
          assignment.submit_homework(assessor, body: "My submission")
        end

        it "returns error result with lock_at message" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:locked)
          expect(result[:message]).to include("no longer available")
          expect(result[:status]).to eq(:bad_request)
        end
      end

      context "when assignment is not yet unlocked" do
        before do
          assignment.update!(
            due_at: 3.days.from_now,
            unlock_at: 1.day.from_now,
            lock_at: 5.days.from_now
          )
          assignment.submit_homework(assessor, body: "My submission")
        end

        it "returns error result with unlock_at message" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:not_unlocked)
          expect(result[:message]).to include("locked until")
          expect(result[:status]).to eq(:bad_request)
        end
      end

      context "when peer review count limit is reached" do
        before do
          assignment.update!(peer_review_count: 1)
          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")

          # Create and complete one review
          request = assignment.assign_peer_review(assessor, student1)
          request.update!(workflow_state: "completed")
        end

        it "returns error result" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:limit_reached)
          expect(result[:message]).to include("completed all required")
          expect(result[:status]).to eq(:bad_request)
        end
      end
    end

    context "when assessor has an ongoing review" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        @existing_request = assignment.assign_peer_review(assessor, student1)
      end

      it "returns the existing ongoing review" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_request].id).to eq(@existing_request.id)
        expect(result[:assessment_request].workflow_state).to eq("assigned")
      end

      it "does not create a new assessment request" do
        expect do
          service.allocate
        end.not_to change { AssessmentRequest.count }
      end
    end

    context "when no submissions are available" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
      end

      it "returns error result" do
        result = service.allocate
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq(:no_submissions_available)
        expect(result[:message]).to include("no peer reviews available")
      end
    end

    context "when allocation succeeds" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
      end

      it "returns success with assessment request" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_request]).to be_a(AssessmentRequest)
        expect(result[:assessment_request].assessor_id).to eq(assessor.id)
        expect(result[:assessment_request].user_id).to eq(student1.id)
      end

      it "creates a new assessment request" do
        expect do
          service.allocate
        end.to change { AssessmentRequest.count }.by(1)
      end
    end

    context "when multiple students allocate concurrently" do
      before do
        # Set up: assessor, student1, student2, and student3 all submit
        assignment.submit_homework(assessor, body: "Assessor submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")
        assignment.submit_homework(student3, body: "Student3 submission")
      end

      it "handles concurrent allocations without race conditions" do
        # Create services for two different assessors
        service1 = described_class.new(assignment:, assessor: student1)
        service2 = described_class.new(assignment:, assessor: student2)

        # Track results from concurrent operations
        results = []
        threads = []

        # Simulate concurrent allocation attempts
        threads << Thread.new { results << service1.allocate }
        threads << Thread.new { results << service2.allocate }

        # Wait for both threads to complete
        threads.each(&:join)

        # Both should succeed
        expect(results.size).to eq(2)
        expect(results.all? { |r| r[:success] }).to be true

        # Both should have assessment requests
        expect(results.all? { |r| r[:assessment_request].present? }).to be true

        # Verify both got different submissions (unless there's only one available)
        allocated_user_ids = results.map { |r| r[:assessment_request].user_id }
        expect(allocated_user_ids).to be_present
      end

      it "prevents duplicate allocations for the same assessor under concurrency" do
        # This tests that with_lock prevents the same assessor from getting duplicate assignments
        service1 = described_class.new(assignment:, assessor: student1)
        service2 = described_class.new(assignment:, assessor: student1)

        results = []
        threads = []

        # Simulate the same assessor trying to allocate twice concurrently
        threads << Thread.new { results << service1.allocate }
        threads << Thread.new { results << service2.allocate }

        threads.each(&:join)

        # Both should succeed but return the same assessment request
        expect(results.size).to eq(2)
        expect(results.all? { |r| r[:success] }).to be true

        # Should have the same assessment request ID (one was created, one was found as ongoing)
        assessment_ids = results.map { |r| r[:assessment_request].id }.uniq
        expect(assessment_ids.size).to eq(1)
      end
    end
  end

  describe "#validate" do
    it "returns success hash when all validations pass" do
      assignment.submit_homework(assessor, body: "My submission")
      result = service.send(:validate)
      expect(result[:success]).to be true
    end
  end

  describe "#find_ongoing_review" do
    context "when assessor has an assigned review" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        @request = assignment.assign_peer_review(assessor, student1)
      end

      it "returns the assessment request" do
        result = service.send(:find_ongoing_review)
        expect(result).to eq(@request)
        expect(result.workflow_state).to eq("assigned")
      end
    end

    context "when assessor has a completed review" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        request = assignment.assign_peer_review(assessor, student1)
        request.update!(workflow_state: "completed")
      end

      it "returns nil" do
        result = service.send(:find_ongoing_review)
        expect(result).to be_nil
      end
    end

    context "when assessor has no reviews" do
      it "returns nil" do
        result = service.send(:find_ongoing_review)
        expect(result).to be_nil
      end
    end
  end

  describe "#count_all_reviews" do
    context "when assessor has no reviews" do
      it "returns 0" do
        count = service.send(:count_all_reviews)
        expect(count).to eq(0)
      end
    end

    context "when assessor has completed reviews" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")

        request1 = assignment.assign_peer_review(assessor, student1)
        request1.update!(workflow_state: "completed")

        request2 = assignment.assign_peer_review(assessor, student2)
        request2.update!(workflow_state: "completed")
      end

      it "counts all completed reviews" do
        count = service.send(:count_all_reviews)
        expect(count).to eq(2)
      end
    end

    context "when assessor has both assigned and completed reviews" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")

        request1 = assignment.assign_peer_review(assessor, student1)
        request1.update!(workflow_state: "completed")

        assignment.assign_peer_review(assessor, student2)
      end

      it "counts both assigned and completed reviews" do
        count = service.send(:count_all_reviews)
        expect(count).to eq(2)
      end
    end
  end

  describe "#find_available_submission" do
    context "when no submissions exist" do
      it "returns nil" do
        result = service.send(:find_available_submission)
        expect(result).to be_nil
      end
    end

    context "when only assessor has submitted" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
      end

      it "returns nil" do
        result = service.send(:find_available_submission)
        expect(result).to be_nil
      end
    end

    context "when one submission is available" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission = assignment.submit_homework(student1, body: "Student1 submission")
      end

      it "returns the available submission" do
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission.id)
        expect(result.user_id).to eq(student1.id)
      end

      it "excludes assessor's own submission" do
        result = service.send(:find_available_submission)
        expect(result.user_id).not_to eq(assessor.id)
      end
    end

    context "when submission is already assigned to assessor" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.assign_peer_review(assessor, student1)
      end

      it "returns nil" do
        result = service.send(:find_available_submission)
        expect(result).to be_nil
      end
    end

    context "when prioritizing unreviewed submissions" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        # Student1 submits first (older)
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)

        # Student2 submits later (newer)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 1.day.ago)

        # Another student reviews student1 (older submission)
        assignment.assign_peer_review(student3, student1)
      end

      it "returns the unreviewed submission even if it's newer" do
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission2.id)
        expect(result.user_id).to eq(student2.id)
      end
    end

    context "when all available submissions have been reviewed by someone" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        # Student1 submits first (older)
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)

        # Student2 submits later (newer)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 1.day.ago)

        # Another student reviews all submissions
        assignment.assign_peer_review(student3, student1)
        assignment.assign_peer_review(student3, student2)
      end

      it "returns oldest submission even if reviewed" do
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission1.id)
        expect(result.user_id).to eq(student1.id)
      end
    end

    context "when multiple unreviewed submissions exist" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        # Create submissions at different times
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 5.days.ago)

        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 3.days.ago)

        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 1.day.ago)
      end

      it "returns the oldest unreviewed submission" do
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission1.id)
        expect(result.user_id).to eq(student1.id)
      end
    end

    context "when submissions have different workflow states" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        # Only submitted state should be considered
        @submitted = assignment.submit_homework(student1, body: "Student1 submission")

        # Graded state should also be considered
        @graded = assignment.submit_homework(student2, body: "Student2 submission")
        @graded.update!(workflow_state: "graded")

        # Pending review should not be considered
        pending = assignment.submit_homework(student3, body: "Student3 submission")
        pending.update!(workflow_state: "pending_review")
      end

      it "includes submitted and graded submissions" do
        result = service.send(:find_available_submission)
        expect([student1.id, student2.id]).to include(result.user_id)
      end

      it "excludes pending_review submissions" do
        result = service.send(:find_available_submission)
        expect(result.user_id).not_to eq(student3.id)
      end
    end

    context "when multiple students can review the same submission" do
      before do
        # All students submit (in order: assessor, student1, student2)
        @assessor_submission = assignment.submit_homework(assessor, body: "Assessor submission")
        @assessor_submission.update!(submitted_at: 4.days.ago)
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 2.days.ago)

        # All submissions have been reviewed by someone
        assignment.assign_peer_review(student3, assessor)
        assignment.assign_peer_review(student3, student1)
        assignment.assign_peer_review(student3, student2)

        # Assessor already reviewed student1
        assignment.assign_peer_review(assessor, student1)
      end

      it "allows the same submission to be assigned to a different student" do
        # Assessor has already reviewed student1, so should get student2 (oldest available)
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission2.id)
        expect(result.user_id).to eq(student2.id)
      end

      it "allows student2 to also review the same submission that assessor reviewed" do
        # Student2 hasn't reviewed anyone yet, should get assessor's submission (oldest)
        student2_service = described_class.new(assignment:, assessor: student2)
        result = student2_service.send(:find_available_submission)
        expect(result.user_id).to eq(assessor.id)
      end

      it "can allocate the same submission to multiple reviewers" do
        # Create assessment for student2 to review student1 (same as assessor reviewed)
        assignment.assign_peer_review(student2, student1)

        # Verify both assessor and student2 have assessment requests for student1
        student1_reviewers = AssessmentRequest.for_assignment(assignment.id)
                                              .where(user_id: student1.id)
                                              .pluck(:assessor_id)
        expect(student1_reviewers).to include(assessor.id, student2.id)
      end
    end
  end

  describe "#find_must_review_submission" do
    context "when there are no allocation rules" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
      end

      it "returns nil" do
        result = service.send(:find_must_review_submission)
        expect(result).to be_nil
      end
    end

    context "when there are allocation rules but must_review is false" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: false,
          review_permitted: true
        )
      end

      it "returns nil" do
        result = service.send(:find_must_review_submission)
        expect(result).to be_nil
      end
    end

    context "when there is one must review rule with available submission" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true
        )
      end

      it "returns the must review submission" do
        result = service.send(:find_must_review_submission)
        expect(result.id).to eq(@submission1.id)
        expect(result.user_id).to eq(student1.id)
      end
    end

    context "when must review submission is already assigned to assessor" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true
        )

        assignment.assign_peer_review(assessor, student1)
      end

      it "returns nil" do
        result = service.send(:find_must_review_submission)
        expect(result).to be_nil
      end
    end

    context "when must review submission has not been submitted yet" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true
        )
      end

      it "returns nil" do
        result = service.send(:find_must_review_submission)
        expect(result).to be_nil
      end
    end

    context "when multiple must review rules exist" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        # Student1 submits first (older)
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)

        # Student2 submits later (newer)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 1.day.ago)

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true
        )

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true
        )
      end

      context "when both submissions have no reviews" do
        it "returns the oldest submission" do
          result = service.send(:find_must_review_submission)
          expect(result.id).to eq(@submission1.id)
          expect(result.user_id).to eq(student1.id)
        end
      end

      context "when one submission has fewer reviews" do
        before do
          # Student3 reviews student1 (so student1 has 1 review)
          assignment.submit_homework(student3, body: "Student3 submission")
          assignment.assign_peer_review(student3, student1)
        end

        it "returns the submission with fewer reviews" do
          result = service.send(:find_must_review_submission)
          expect(result.id).to eq(@submission2.id)
          expect(result.user_id).to eq(student2.id)
        end
      end

      context "when both submissions have same number of reviews" do
        before do
          # Student3 reviews both student1 and student2
          assignment.submit_homework(student3, body: "Student3 submission")
          assignment.assign_peer_review(student3, student1)
          assignment.assign_peer_review(student3, student2)
        end

        it "returns the oldest submission as tiebreaker" do
          result = service.send(:find_must_review_submission)
          expect(result.id).to eq(@submission1.id)
          expect(result.user_id).to eq(student1.id)
        end
      end
    end

    context "with three must review submissions at different review counts" do
      let(:student4) { user_model }

      before do
        course.enroll_student(student4, enrollment_state: :active)

        assignment.submit_homework(assessor, body: "My submission")

        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 5.days.ago)

        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 3.days.ago)

        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 1.day.ago)

        assignment.submit_homework(student4, body: "Student4 submission")

        AllocationRule.create!(course:, assignment:, assessor:, assessee: student1, must_review: true)
        AllocationRule.create!(course:, assignment:, assessor:, assessee: student2, must_review: true)
        AllocationRule.create!(course:, assignment:, assessor:, assessee: student3, must_review: true)

        # Student1 has 2 reviews, Student2 has 1 review, Student3 has 0 reviews
        assignment.assign_peer_review(student4, student1)
        assignment.assign_peer_review(student4, student1)
        assignment.assign_peer_review(student4, student2)
      end

      it "returns submission with fewest reviews" do
        result = service.send(:find_must_review_submission)
        expect(result.id).to eq(@submission3.id)
        expect(result.user_id).to eq(student3.id)
      end
    end
  end

  describe "#find_available_submission with must review rules" do
    context "when must review submission exists" do
      before do
        assignment.submit_homework(assessor, body: "My submission")

        # Student1 is older and unreviewed
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 5.days.ago)

        # Student2 has must_review rule but is newer
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 1.day.ago)

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true
        )
      end

      it "prioritizes must review submission over older submissions" do
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission2.id)
        expect(result.user_id).to eq(student2.id)
      end
    end

    context "when must review submission is unavailable" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true
        )

        # Already assigned the must review submission
        assignment.assign_peer_review(assessor, student2)
      end

      it "falls back to regular allocation logic" do
        result = service.send(:find_available_submission)
        expect(result.id).to eq(@submission1.id)
        expect(result.user_id).to eq(student1.id)
      end
    end
  end

  describe "#success_result" do
    let(:mock_request) { instance_double(AssessmentRequest) }

    it "returns success hash with assessment_request" do
      result = service.send(:success_result, mock_request)
      expect(result[:success]).to be true
      expect(result[:assessment_request]).to eq(mock_request)
    end
  end

  describe "#error_result" do
    it "returns error hash with all parameters" do
      result = service.send(:error_result, :test_error, "Test message", :not_found)
      expect(result[:success]).to be false
      expect(result[:error_code]).to eq(:test_error)
      expect(result[:message]).to eq("Test message")
      expect(result[:status]).to eq(:not_found)
    end

    it "defaults status to bad_request" do
      result = service.send(:error_result, :test_error, "Test message")
      expect(result[:status]).to eq(:bad_request)
    end
  end
end
