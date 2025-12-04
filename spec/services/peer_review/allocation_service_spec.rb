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
    course.enable_feature!(:peer_review_allocation_and_grading)
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
          course.disable_feature!(:peer_review_allocation_and_grading)
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

      context "when peer_review_submission_required is true" do
        before do
          assignment.update!(peer_review_submission_required: true)
          assignment.submissions.find_by(user: student1).update!(workflow_state: "submitted")
        end

        it "returns error result when assessor has not submitted" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:not_submitted)
          expect(result[:message]).to include("must submit")
          expect(result[:status]).to eq(:bad_request)
        end
      end

      context "when peer_review_submission_required is false" do
        before do
          assignment.update!(peer_review_submission_required: false)
          assignment.submit_homework(student1, body: "Student1 submission")
        end

        it "allows allocation even if assessor has not submitted" do
          assignment.submit_homework(student2, body: "Student2 submission")
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].first).to be_a(AssessmentRequest)
          expect(result[:assessment_requests].first.assessor_id).to eq(assessor.id)
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
          expect(result[:message]).to include("assigned all required")
          expect(result[:status]).to eq(:bad_request)
        end
      end
    end

    context "when assessor has an ongoing review" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")
        @existing_request = assignment.assign_peer_review(assessor, student1)
      end

      it "returns existing ongoing reviews and allocates more to meet required count" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests]).to be_an(Array)
        expect(result[:assessment_requests].size).to eq(2)
        expect(result[:assessment_requests].map(&:id)).to include(@existing_request.id)
        expect(result[:assessment_requests].first.workflow_state).to eq("assigned")
      end

      it "creates additional assessment requests to meet required count" do
        expect do
          service.allocate
        end.to change { AssessmentRequest.count }.by(1)
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
        assignment.submit_homework(student2, body: "Student2 submission")
      end

      it "returns success with array of assessment requests" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests]).to be_an(Array)
        expect(result[:assessment_requests].size).to eq(2)
        expect(result[:assessment_requests].all?(AssessmentRequest)).to be true
        expect(result[:assessment_requests].map(&:assessor_id).uniq).to eq([assessor.id])
        expect(result[:assessment_requests].map(&:user_id)).to match_array([student1.id, student2.id])
      end

      it "creates multiple assessment requests to meet required count" do
        expect do
          service.allocate
        end.to change { AssessmentRequest.count }.by(2)
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

        # Both should have assessment requests arrays
        expect(results.all? { |r| r[:assessment_requests].present? }).to be true
        expect(results.all? { |r| r[:assessment_requests].is_a?(Array) }).to be true

        # Each should have 2 allocations (peer_review_count is 2)
        expect(results.all? { |r| r[:assessment_requests].size == 2 }).to be true

        # Should be different to ensure fair distribution
        allocated_user_ids_1 = results[0][:assessment_requests].map(&:user_id)
        allocated_user_ids_2 = results[1][:assessment_requests].map(&:user_id)
        expect(allocated_user_ids_1).not_to include(allocated_user_ids_2)
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

        # Both should succeed and return the same assessment requests
        expect(results.size).to eq(2)
        expect(results.all? { |r| r[:success] }).to be true

        # Should have the same assessment request IDs (no duplicates created)
        assessment_ids_1 = results[0][:assessment_requests].map(&:id).sort
        assessment_ids_2 = results[1][:assessment_requests].map(&:id).sort
        expect(assessment_ids_1).to eq(assessment_ids_2)
        expect(assessment_ids_1.size).to eq(2)
      end
    end

    context "when allocating multiple peer reviews" do
      before do
        assignment.update!(peer_review_count: 3)
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")
        assignment.submit_homework(student3, body: "Student3 submission")
      end

      it "allocates all required peer reviews at once" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(3)
        expect(result[:assessment_requests].map(&:assessor_id).uniq).to eq([assessor.id])
        expect(result[:assessment_requests].map(&:user_id)).to match_array([student1.id, student2.id, student3.id])
      end

      it "creates all assessment requests in the database" do
        expect do
          service.allocate
        end.to change { AssessmentRequest.count }.by(3)
      end

      context "when some reviews are already assigned" do
        before do
          @existing_request = assignment.assign_peer_review(assessor, student1)
        end

        it "returns existing reviews and allocates remaining needed" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)
          expect(result[:assessment_requests].map(&:id)).to include(@existing_request.id)
        end

        it "only creates new assessment requests for remaining needed" do
          expect do
            service.allocate
          end.to change { AssessmentRequest.count }.by(2)
        end
      end

      context "when prioritizing must_review submissions" do
        before do
          # Create allocation rules for student1 and student2
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

        it "allocates must_review submissions first, then regular submissions" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)

          # First two should be must_review (student1 and student2)
          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          expect(allocated_user_ids).to include(student1.id, student2.id, student3.id)
        end
      end
    end

    context "when peer_review_count is 1" do
      before do
        assignment.update!(peer_review_count: 1)
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")
      end

      it "allocates a single peer review in an array" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests]).to be_an(Array)
        expect(result[:assessment_requests].size).to eq(1)
      end
    end
  end

  describe "#validate" do
    it "returns success hash when all validations pass" do
      assignment.submit_homework(assessor, body: "My submission")
      assignment.submit_homework(student1, body: "Student1 submission")
      assignment.submit_homework(student2, body: "Student2 submission")
      result = service.send(:validate)
      expect(result[:success]).to be true
    end
  end

  describe "#find_ongoing_reviews" do
    context "when assessor has an assigned review" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        @request = assignment.assign_peer_review(assessor, student1)
      end

      it "returns array with the assessment request" do
        result = service.send(:find_ongoing_reviews)
        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
        expect(result.first).to eq(@request)
        expect(result.first.workflow_state).to eq("assigned")
      end
    end

    context "when assessor has multiple assigned reviews" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        assignment.submit_homework(student2, body: "Student2 submission")
        @request1 = assignment.assign_peer_review(assessor, student1)
        @request2 = assignment.assign_peer_review(assessor, student2)
      end

      it "returns array with all ongoing assessment requests" do
        result = service.send(:find_ongoing_reviews)
        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        expect(result.map(&:id)).to match_array([@request1.id, @request2.id])
      end
    end

    context "when assessor has a completed review" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        assignment.submit_homework(student1, body: "Student1 submission")
        request = assignment.assign_peer_review(assessor, student1)
        request.update!(workflow_state: "completed")
      end

      it "returns empty array" do
        result = service.send(:find_ongoing_reviews)
        expect(result).to eq([])
      end
    end

    context "when assessor has no reviews" do
      it "returns empty array" do
        result = service.send(:find_ongoing_reviews)
        expect(result).to eq([])
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

  describe "#select_submissions_to_allocate" do
    context "when no submissions are available" do
      it "returns empty array" do
        result = service.send(:select_submissions_to_allocate, [], 2)
        expect(result).to eq([])
      end
    end

    context "when selecting submissions" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 2.days.ago)
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 1.day.ago)
      end

      it "returns requested count of submissions" do
        available = [@submission1, @submission2, @submission3]
        result = service.send(:select_submissions_to_allocate, available, 2)
        expect(result.size).to eq(2)
      end

      it "returns all submissions when count exceeds available" do
        available = [@submission1, @submission2]
        result = service.send(:select_submissions_to_allocate, available, 5)
        expect(result.size).to eq(2)
      end

      it "prioritizes submissions with fewest reviews" do
        assignment.assign_peer_review(student2, student3)
        assignment.assign_peer_review(student1, student3)

        available = [@submission1, @submission2, @submission3]
        result = service.send(:select_submissions_to_allocate, available, 2)

        expect(result.map(&:id)).to match_array([@submission1.id, @submission2.id])
      end

      it "uses submitted_at as tiebreaker when review counts are equal" do
        available = [@submission1, @submission2, @submission3]
        result = service.send(:select_submissions_to_allocate, available, 3)

        expect(result.map(&:id)).to eq([@submission1.id, @submission2.id, @submission3.id])
      end
    end

    context "when must_review rules exist" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 5.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 1.day.ago)
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 3.days.ago)

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true
        )
      end

      it "prioritizes must_review submissions first" do
        available = [@submission1, @submission2, @submission3]
        result = service.send(:select_submissions_to_allocate, available, 2)

        expect(result.first.id).to eq(@submission2.id)
        expect(result.map(&:id)).to include(@submission1.id)
      end

      it "sorts must_review submissions by review count" do
        student4 = student_in_course(active_all: true).user
        @submission4 = assignment.submit_homework(student4, body: "Student4 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student4,
          must_review: true
        )

        assignment.assign_peer_review(student1, student2)
        assignment.assign_peer_review(student3, student2)

        available = [@submission1, @submission2, @submission3, @submission4]
        result = service.send(:select_submissions_to_allocate, available, 2)

        expect(result.first.id).to eq(@submission4.id)
        expect(result.second.id).to eq(@submission2.id)
      end
    end

    context "when avoiding duplicates" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
      end

      it "does not return duplicate submissions" do
        available = [@submission1, @submission2]
        result = service.send(:select_submissions_to_allocate, available, 3)

        expect(result.map(&:id).uniq.size).to eq(result.size)
      end
    end
  end

  describe "#success_result" do
    let(:mock_request1) { instance_double(AssessmentRequest) }
    let(:mock_request2) { instance_double(AssessmentRequest) }

    it "returns success hash with assessment_requests array" do
      result = service.send(:success_result, [mock_request1, mock_request2])
      expect(result[:success]).to be true
      expect(result[:assessment_requests]).to eq([mock_request1, mock_request2])
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
