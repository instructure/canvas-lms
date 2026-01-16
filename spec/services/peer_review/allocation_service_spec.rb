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
          expect(result[:status]).to eq(:forbidden)
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
          expect(result[:status]).to eq(:forbidden)
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
          expect(result[:status]).to eq(:forbidden)
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
          expect(result[:status]).to eq(:forbidden)
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
          expect(result[:status]).to eq(:forbidden)
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
          expect(result[:status]).to eq(:forbidden)
        end
      end

      context "when peer review start date has not been reached" do
        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          assignment.reload.peer_review_sub_assignment.update!(unlock_at: 2.days.from_now)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")
        end

        it "returns error result with peer review start date message" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_review_not_started)
          expect(result[:message]).to include("not available until")
          expect(result[:status]).to eq(:forbidden)
        end
      end

      context "when peer review start date has passed" do
        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          assignment.reload.peer_review_sub_assignment.update!(unlock_at: 1.day.ago)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")
          assignment.submit_homework(student2, body: "Student2 submission")
        end

        it "allows allocation" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests]).to be_an(Array)
          expect(result[:assessment_requests].size).to eq(2)
        end
      end

      context "when peer review unlock_at is not set" do
        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          assignment.reload.peer_review_sub_assignment.update!(unlock_at: nil)

          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")
          assignment.submit_homework(student2, body: "Student2 submission")
        end

        context "when parent assignment due_at is in the future" do
          before do
            assignment.update!(due_at: 1.day.from_now)
          end

          it "uses parent assignment due_at and blocks allocation" do
            result = service.allocate
            expect(result[:success]).to be false
            expect(result[:error_code]).to eq(:peer_review_not_started)
            expect(result[:message]).to include("not available until")
          end
        end

        context "when parent assignment due_at is in the past" do
          before do
            assignment.update!(due_at: 1.day.ago)
          end

          it "uses parent assignment due_at and allows allocation" do
            result = service.allocate
            expect(result[:success]).to be true
            expect(result[:assessment_requests].size).to eq(2)
          end
        end

        context "when parent assignment due_at is nil" do
          before do
            assignment.update!(due_at: nil)
          end

          it "allows allocation when no dates are set" do
            result = service.allocate
            expect(result[:success]).to be true
            expect(result[:assessment_requests].size).to eq(2)
          end
        end
      end

      context "when peer review start date has override for specific section" do
        let(:section1) { course.course_sections.create!(name: "Section 1") }
        let(:section2) { course.course_sections.create!(name: "Section 2") }
        let(:assessor_section1) { user_model }
        let(:assessor_section2) { user_model }
        let(:student_section1) { user_model }
        let(:student_section2) { user_model }

        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          peer_review_sub = assignment.reload.peer_review_sub_assignment
          peer_review_sub.update!(unlock_at: 3.days.from_now)

          course.enroll_student(assessor_section1, enrollment_state: :active, section: section1)
          course.enroll_student(assessor_section2, enrollment_state: :active, section: section2)
          course.enroll_student(student_section1, enrollment_state: :active, section: section1)
          course.enroll_student(student_section2, enrollment_state: :active, section: section2)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(assessor_section1, body: "Assessor1 submission")
          assignment.submit_homework(assessor_section2, body: "Assessor2 submission")
          assignment.submit_homework(student_section1, body: "Student section1 submission")
          assignment.submit_homework(student_section2, body: "Student section2 submission")

          parent_override1 = assignment.assignment_overrides.create!(
            set: section1,
            due_at: 2.days.ago
          )

          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_override1,
            set: section1,
            unlock_at: 1.day.ago
          )
        end

        it "allows allocation for section1 assessor with override in the past" do
          service1 = described_class.new(assignment:, assessor: assessor_section1)
          result = service1.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests]).to be_an(Array)
        end

        it "blocks allocation for section2 assessor with base unlock_at in the future" do
          service2 = described_class.new(assignment:, assessor: assessor_section2)
          result = service2.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_review_not_started)
          expect(result[:message]).to include("not available until")
        end
      end

      context "when peer review start date has ADHOC override" do
        let(:adhoc_student) { user_model }
        let(:regular_student) { user_model }

        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          peer_review_sub = assignment.reload.peer_review_sub_assignment
          peer_review_sub.update!(unlock_at: 3.days.from_now)

          course.enroll_student(adhoc_student, enrollment_state: :active)
          course.enroll_student(regular_student, enrollment_state: :active)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(adhoc_student, body: "ADHOC student submission")
          assignment.submit_homework(regular_student, body: "Regular student submission")
          assignment.submit_homework(student1, body: "Student1 submission")

          parent_adhoc = assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            due_at: 2.days.ago
          )
          parent_adhoc.assignment_override_students.create!(user: adhoc_student)

          peer_review_adhoc = peer_review_sub.assignment_overrides.create!(
            parent_override: parent_adhoc,
            set_type: "ADHOC",
            unlock_at: 1.day.ago
          )
          peer_review_adhoc.assignment_override_students.create!(user: adhoc_student)
        end

        it "allows allocation for student with ADHOC override in the past" do
          service_adhoc = described_class.new(assignment:, assessor: adhoc_student)
          result = service_adhoc.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests]).to be_an(Array)
        end

        it "blocks allocation for student without override (using base unlock_at in the future)" do
          service_regular = described_class.new(assignment:, assessor: regular_student)
          result = service_regular.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_review_not_started)
        end
      end

      context "when peer review lock date has passed" do
        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          assignment.reload.peer_review_sub_assignment.update!(lock_at: 1.day.ago)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")
        end

        it "returns error result with peer review lock date message" do
          result = service.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_review_locked)
          expect(result[:message]).to include("no longer available")
          expect(result[:status]).to eq(:forbidden)
        end
      end

      context "when peer review lock date has not passed" do
        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          assignment.reload.peer_review_sub_assignment.update!(
            unlock_at: 1.day.ago,
            lock_at: 1.day.from_now
          )

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")
          assignment.submit_homework(student2, body: "Student2 submission")
        end

        it "allows allocation" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests]).to be_an(Array)
          expect(result[:assessment_requests].size).to eq(2)
        end
      end

      context "when peer review lock_at is not set" do
        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          assignment.reload.peer_review_sub_assignment.update!(
            unlock_at: 1.day.ago,
            lock_at: nil
          )

          assignment.submit_homework(assessor, body: "My submission")
          assignment.submit_homework(student1, body: "Student1 submission")
          assignment.submit_homework(student2, body: "Student2 submission")
        end

        it "allows allocation when no lock date is set" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(2)
        end
      end

      context "when peer review lock date has override for specific section" do
        let(:section1) { course.course_sections.create!(name: "Section 1") }
        let(:section2) { course.course_sections.create!(name: "Section 2") }
        let(:assessor_section1) { user_model }
        let(:assessor_section2) { user_model }
        let(:student_section1) { user_model }
        let(:student_section2) { user_model }

        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          peer_review_sub = assignment.reload.peer_review_sub_assignment
          peer_review_sub.update!(
            unlock_at: 3.days.ago,
            lock_at: 2.days.from_now
          )

          course.enroll_student(assessor_section1, enrollment_state: :active, section: section1)
          course.enroll_student(assessor_section2, enrollment_state: :active, section: section2)
          course.enroll_student(student_section1, enrollment_state: :active, section: section1)
          course.enroll_student(student_section2, enrollment_state: :active, section: section2)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(assessor_section1, body: "Assessor1 submission")
          assignment.submit_homework(assessor_section2, body: "Assessor2 submission")
          assignment.submit_homework(student_section1, body: "Student section1 submission")
          assignment.submit_homework(student_section2, body: "Student section2 submission")

          parent_override1 = assignment.assignment_overrides.create!(
            set: section1,
            due_at: 2.days.ago
          )

          peer_review_sub.assignment_overrides.create!(
            parent_override: parent_override1,
            set: section1,
            lock_at: 1.day.ago
          )
        end

        it "blocks allocation for section1 assessor with override lock date in the past" do
          service1 = described_class.new(assignment:, assessor: assessor_section1)
          result = service1.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_review_locked)
          expect(result[:message]).to include("no longer available")
        end

        it "allows allocation for section2 assessor with base lock_at in the future" do
          service2 = described_class.new(assignment:, assessor: assessor_section2)
          result = service2.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests]).to be_an(Array)
        end
      end

      context "when peer review lock date has ADHOC override" do
        let(:adhoc_student) { user_model }
        let(:regular_student) { user_model }

        before do
          PeerReview::PeerReviewCreatorService.new(
            parent_assignment: assignment,
            points_possible: 5
          ).call

          peer_review_sub = assignment.reload.peer_review_sub_assignment
          peer_review_sub.update!(
            unlock_at: 3.days.ago,
            lock_at: 2.days.from_now
          )

          course.enroll_student(adhoc_student, enrollment_state: :active)
          course.enroll_student(regular_student, enrollment_state: :active)

          assignment.update!(due_at: 3.days.ago)
          assignment.submit_homework(adhoc_student, body: "ADHOC student submission")
          assignment.submit_homework(regular_student, body: "Regular student submission")
          assignment.submit_homework(student1, body: "Student1 submission")

          parent_adhoc = assignment.assignment_overrides.create!(
            set_type: "ADHOC",
            due_at: 2.days.ago
          )
          parent_adhoc.assignment_override_students.create!(user: adhoc_student)

          peer_review_adhoc = peer_review_sub.assignment_overrides.create!(
            parent_override: parent_adhoc,
            set_type: "ADHOC",
            lock_at: 1.day.ago
          )
          peer_review_adhoc.assignment_override_students.create!(user: adhoc_student)
        end

        it "blocks allocation for student with ADHOC override lock date in the past" do
          service_adhoc = described_class.new(assignment:, assessor: adhoc_student)
          result = service_adhoc.allocate
          expect(result[:success]).to be false
          expect(result[:error_code]).to eq(:peer_review_locked)
          expect(result[:message]).to include("no longer available")
        end

        it "allows allocation for student without override (using base lock_at in the future)" do
          service_regular = described_class.new(assignment:, assessor: regular_student)
          result = service_regular.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests]).to be_an(Array)
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
          expect(result[:status]).to eq(:forbidden)
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

      context "when peer_review_across_sections is true" do
        let(:section1) { course.course_sections.create!(name: "Section 1") }
        let(:section2) { course.course_sections.create!(name: "Section 2") }
        let(:assessor2) { user_model }
        let(:student4) { user_model }
        let(:student5) { user_model }
        let(:section_assignment) do
          assignment_model(
            course:,
            title: "Section Peer Review Assignment",
            peer_reviews: true,
            peer_review_count: 2,
            peer_review_across_sections: true,
            automatic_peer_reviews: false,
            submission_types: "online_text_entry"
          )
        end

        before do
          # Enroll assessor in section1
          course.enroll_student(assessor2, enrollment_state: :active, section: section1)

          # Enroll students in different sections
          course.enroll_student(student4, enrollment_state: :active, section: section1)
          course.enroll_student(student5, enrollment_state: :active, section: section2)

          section_assignment.submit_homework(assessor2, body: "Assessor submission")
          section_assignment.submit_homework(student4, body: "Student4 submission")
          section_assignment.submit_homework(student5, body: "Student5 submission")
        end

        it "allocates peer reviews from any section" do
          service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
          result = service2.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(2)
          expect(result[:assessment_requests].map(&:user_id)).to match_array([student4.id, student5.id])
        end
      end

      context "when peer_review_across_sections is false" do
        let(:section1) { course.course_sections.create!(name: "Section 1") }
        let(:section2) { course.course_sections.create!(name: "Section 2") }
        let(:assessor2) { user_model }
        let(:student4) { user_model }
        let(:student5) { user_model }
        let(:student6) { user_model }
        let(:section_assignment) do
          assignment_model(
            course:,
            title: "Section Peer Review Assignment",
            peer_reviews: true,
            peer_review_count: 2,
            peer_review_across_sections: false,
            automatic_peer_reviews: false,
            submission_types: "online_text_entry"
          )
        end

        before do
          # Section 2
          course.enroll_student(student6, enrollment_state: :active, section: section2)
          section_assignment.submit_homework(student6, body: "Student6 submission")

          # Section 1
          course.enroll_student(assessor2, enrollment_state: :active, section: section1)
          course.enroll_student(student4, enrollment_state: :active, section: section1)
          course.enroll_student(student5, enrollment_state: :active, section: section1)
          section_assignment.submit_homework(assessor2, body: "Assessor submission")
          section_assignment.submit_homework(student4, body: "Student4 submission")
          section_assignment.submit_homework(student5, body: "Student5 submission")
        end

        it "only allocates peer reviews from the same section" do
          service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
          result = service2.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(2)
          expect(result[:assessment_requests].map(&:user_id)).to match_array([student4.id, student5.id])
        end

        it "does not allocate reviews from different sections" do
          service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
          result = service2.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].map(&:user_id)).not_to include(student6.id)
        end

        context "when there are insufficient submissions in the same section" do
          before do
            section_assignment.submissions.find_by(user: student5).destroy!
          end

          it "only allocates what is available in the same section" do
            service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
            result = service2.allocate
            expect(result[:success]).to be true
            expect(result[:assessment_requests].size).to eq(1)
            expect(result[:assessment_requests].first.user_id).to eq(student4.id)
          end
        end

        context "when assessor is in multiple sections" do
          before do
            course.enroll_student(assessor2, enrollment_state: :active, section: section2, allow_multiple_enrollments: true)
          end

          it "allocates from all sections the assessor is enrolled in" do
            service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
            result = service2.allocate
            expect(result[:success]).to be true
            expect(result[:assessment_requests].size).to eq(2)
            # Should be able to allocate from both sections now
            expect(result[:assessment_requests].map(&:user_id)).to match_array([student6.id, student4.id])
          end
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

        it "does not have N+1 queries when fetching must_review users" do
          student4 = student_in_course(active_all: true).user
          student5 = student_in_course(active_all: true).user

          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student4,
            must_review: true
          )
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student5,
            must_review: true
          )

          # Count User.find queries
          user_find_count = 0
          allow(User).to receive(:find).and_wrap_original do |method, *args|
            user_find_count += 1
            method.call(*args)
          end

          service.allocate

          # Should only call User.find once for all must_review users, not once per user
          expect(user_find_count).to eq(1)
        end

        it "allocates must_review even when assessee has not submitted" do
          assignment.submissions.find_by(user: student1).update!(workflow_state: "unsubmitted", submission_type: nil)

          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)

          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          expect(allocated_user_ids).to include(student1.id, student2.id, student3.id)
        end

        it "allocates all must_review users regardless of submission status, then fills remaining from available pool" do
          assignment.submissions.find_by(user: student1).update!(workflow_state: "unsubmitted", submission_type: nil)
          assignment.submissions.find_by(user: student2).update!(workflow_state: "unsubmitted", submission_type: nil)

          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)

          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          # All three allocated: 2 must_review (not submitted) + 1 regular (submitted)
          expect(allocated_user_ids).to match_array([student1.id, student2.id, student3.id])
        end

        context "when peer_review_across_sections is false" do
          let(:section1) { course.course_sections.create!(name: "Section 1") }
          let(:section2) { course.course_sections.create!(name: "Section 2") }
          let(:assessor_section1) { user_model }
          let(:student_section1) { user_model }
          let(:student_section2) { user_model }
          let(:section_assignment) do
            assignment_model(
              course:,
              title: "Section Peer Review Assignment",
              peer_reviews: true,
              peer_review_count: 2,
              peer_review_across_sections: false,
              automatic_peer_reviews: false,
              submission_types: "online_text_entry"
            )
          end

          before do
            course.enroll_student(assessor_section1, enrollment_state: :active, section: section1)
            course.enroll_student(student_section1, enrollment_state: :active, section: section1)
            course.enroll_student(student_section2, enrollment_state: :active, section: section2)

            section_assignment.submit_homework(assessor_section1, body: "Assessor submission")
            section_assignment.submit_homework(student_section1, body: "Student section1 submission")

            # Student in section2 has must_review rule but is in different section
            AllocationRule.create!(
              course:,
              assignment: section_assignment,
              assessor: assessor_section1,
              assessee: student_section2,
              must_review: true
            )

            # Student in section1 also has must_review rule and hasn't submitted
            AllocationRule.create!(
              course:,
              assignment: section_assignment,
              assessor: assessor_section1,
              assessee: student_section1,
              must_review: true
            )
            section_assignment.submissions.find_by(user: student_section1).update!(workflow_state: "unsubmitted", submission_type: nil)
          end

          it "respects section restrictions for must_review rules" do
            service2 = described_class.new(assignment: section_assignment, assessor: assessor_section1)
            result = service2.allocate
            expect(result[:success]).to be true

            allocated_user_ids = result[:assessment_requests].map(&:user_id)
            expect(allocated_user_ids).to include(student_section1.id)
            expect(allocated_user_ids).not_to include(student_section2.id)
          end
        end
      end

      context "when prioritizing should_review submissions" do
        before do
          # Create should_review allocation rule for student1
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student1,
            must_review: false,
            review_permitted: true
          )
        end

        it "allocates should_review submissions before regular submissions" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)

          # Student1 should be prioritized due to should_review rule
          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          expect(allocated_user_ids).to include(student1.id)
          expect(allocated_user_ids.first).to eq(student1.id)
        end

        it "sorts should_review submissions by review count" do
          student4 = student_in_course(active_all: true).user
          assignment.submit_homework(student4, body: "Student4 submission")

          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student4,
            must_review: false,
            review_permitted: true
          )

          # Give student1 more reviews than student4
          assignment.assign_peer_review(student2, student1)
          assignment.assign_peer_review(student3, student1)

          result = service.allocate
          expect(result[:success]).to be true

          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          # student4 should come first (fewer reviews), student1 second (should_review but has more reviews)
          expect(allocated_user_ids.first).to eq(student4.id)
          expect(allocated_user_ids.second).to eq(student1.id)
        end
      end

      context "when mixing must_review, should_review, and regular submissions" do
        let(:student4) { student_in_course(active_all: true).user }

        before do
          assignment.submit_homework(student4, body: "Student4 submission")

          # Must review student1
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student1,
            must_review: true,
            review_permitted: true
          )

          # Should review student2
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student2,
            must_review: false,
            review_permitted: true
          )

          # student3 and student4 have no rules (regular)
        end

        it "prioritizes must_review first, should_review second, then regular submissions" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)

          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          # Must review first
          expect(allocated_user_ids.first).to eq(student1.id)
          # Should review second
          expect(allocated_user_ids.second).to eq(student2.id)
          # Regular submission last (either student3 or student4)
          expect(allocated_user_ids.last).to be_in([student3.id, student4.id])
        end

        it "allocates all submissions when peer_review_count matches total students" do
          assignment.update!(peer_review_count: 4)
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(4)

          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          # Must review first
          expect(allocated_user_ids.first).to eq(student1.id)
          # Should review second
          expect(allocated_user_ids.second).to eq(student2.id)
          # Regular submissions last
          expect(allocated_user_ids[2..]).to match_array([student3.id, student4.id])
        end
      end

      context "when should_review submission is not available" do
        let(:student4) { student_in_course(active_all: true).user }

        before do
          # Student4 has a should_review rule but hasn't submitted yet
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student4,
            must_review: false,
            review_permitted: true
          )

          # Student4's submission exists but is unsubmitted
          assignment.submissions.find_by(user: student4).update!(workflow_state: "unsubmitted", submission_type: nil)
        end

        it "skips the should_review rule and allocates other available submissions" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)

          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          # Should not include student4 since they didn't submit
          expect(allocated_user_ids).not_to include(student4.id)
          # Should allocate the three students who did submit
          expect(allocated_user_ids).to match_array([student1.id, student2.id, student3.id])
        end
      end

      context "when only should_review rules exist" do
        before do
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student1,
            must_review: false,
            review_permitted: true
          )
          AllocationRule.create!(
            course:,
            assignment:,
            assessor:,
            assessee: student2,
            must_review: false,
            review_permitted: true
          )
        end

        it "allocates all should_review submissions when they match the required count" do
          assignment.update!(peer_review_count: 2)
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(2)
          expect(result[:assessment_requests].map(&:user_id)).to match_array([student1.id, student2.id])
        end

        it "includes regular submissions when should_review count is insufficient" do
          result = service.allocate
          expect(result[:success]).to be true
          expect(result[:assessment_requests].size).to eq(3)
          allocated_user_ids = result[:assessment_requests].map(&:user_id)
          # Should review first
          expect(allocated_user_ids[0..1]).to match_array([student1.id, student2.id])
          # Regular submission last
          expect(allocated_user_ids.last).to eq(student3.id)
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

      it "uses submitted_at as tiebreaker when multiple must_review submissions have equal review counts" do
        student4 = student_in_course(active_all: true).user
        @submission4 = assignment.submit_homework(student4, body: "Student4 submission")
        @submission4.update!(submitted_at: 4.days.ago)

        # Add must_review rule for student4
        # (student2 already has must_review from before block)
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student4,
          must_review: true
        )

        # Submission dates:
        # student2: 1 day ago (must_review)
        # student4: 4 days ago (must_review)
        # student1: 5 days ago (regular - no rule)
        # student3: 3 days ago (regular - no rule)

        available = [@submission1, @submission2, @submission3, @submission4]
        result = service.send(:select_submissions_to_allocate, available, 2)

        # Both student2 and student4 have must_review priority and 0 reviews
        # Should sort by submitted_at (oldest first): student4 (4 days) before student2 (1 day)
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

    context "when recycling submissions that have all been reviewed" do
      let(:student4) { user_model }
      let(:student5) { user_model }

      before do
        course.enroll_student(student4, enrollment_state: :active)
        course.enroll_student(student5, enrollment_state: :active)

        assignment.submit_homework(assessor, body: "Assessor submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 5.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 4.days.ago)
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 3.days.ago)

        # All submissions have been reviewed at least once
        # submission1: 1 review
        assignment.assign_peer_review(student4, student1)

        # submission2: 2 reviews
        assignment.assign_peer_review(student4, student2)
        assignment.assign_peer_review(student5, student2)

        # submission3: 3 reviews
        assignment.assign_peer_review(student4, student3)
        assignment.assign_peer_review(student5, student3)
        assignment.assign_peer_review(student1, student3)
      end

      it "properly recycles by prioritizing fewest reviews first" do
        available = [@submission1, @submission2, @submission3]
        result = service.send(:select_submissions_to_allocate, available, 2)

        expect(result.map(&:id)).to eq([@submission1.id, @submission2.id])
      end

      it "uses submitted_at to break ties when review counts are equal" do
        # Give submission1 and submission2 the same review count
        assignment.assign_peer_review(student5, student1)

        available = [@submission1, @submission2, @submission3]
        result = service.send(:select_submissions_to_allocate, available, 2)

        expect(result.map(&:id)).to eq([@submission1.id, @submission2.id])
      end

      it "handles submissions with identical review counts and submitted_at consistently" do
        time = 5.days.ago
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: time)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: time)
        available = [@submission1, @submission2]
        result = service.send(:select_submissions_to_allocate, available, 1)
        # Should return consistently (e.g., by submission.id)
        expect(result.size).to eq(1)
      end
    end

    context "when must_not_review rules exist" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true,
          review_permitted: false,
          applies_to_assessor: true
        )

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student3,
          must_review: true,
          review_permitted: false,
          applies_to_assessor: false
        )
      end

      it "excludes submissions with must_not_review rules" do
        available = service.send(:preload_available_submissions)
        expect(available.map(&:user_id)).not_to include(student2.id)
        expect(available.map(&:user_id)).to include(student1.id)
      end

      it "does not allocate submissions with must_not_review rules" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].map(&:user_id)).not_to include(student2.id, student3.id)
        expect(result[:assessment_requests].map(&:user_id)).to include(student1.id)
      end
    end

    context "when mixing must_review and must_not_review rules" do
      before do
        assignment.update!(peer_review_count: 3)
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 2.days.ago)
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 1.day.ago)

        student4 = student_in_course(active_all: true).user
        @submission4 = assignment.submit_homework(student4, body: "Student4 submission")
        @submission4.update!(submitted_at: 4.days.ago)

        # Must review student1
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true,
          review_permitted: true
        )

        # Must not review student2
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true,
          review_permitted: false
        )
      end

      it "prioritizes must_review submissions and excludes must_not_review submissions" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(3)

        allocated_user_ids = result[:assessment_requests].map(&:user_id)

        expect(allocated_user_ids).to include(student1.id)
        expect(allocated_user_ids).not_to include(student2.id)
        expect(allocated_user_ids).to include(student3.id)
      end

      it "filters out must_not_review in preload and prioritizes must_review in selection" do
        available = service.send(:preload_available_submissions)
        expect(available.map(&:user_id)).not_to include(student2.id)
        expect(available.map(&:user_id)).to include(student1.id, student3.id)

        result = service.send(:select_submissions_to_allocate, available, 3)
        expect(result.first.user_id).to eq(student1.id)
        expect(result.map(&:user_id)).not_to include(student2.id)
      end
    end

    context "when all available submissions have must_not_review rules" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true,
          review_permitted: false,
          applies_to_assessor: true
        )

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: true,
          review_permitted: false,
          applies_to_assessor: false
        )
      end

      it "returns error when no submissions are available" do
        result = service.allocate
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq(:no_submissions_available)
        expect(result[:message]).to include("no peer reviews available")
      end
    end

    context "when should_not_review rules exist" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: false,
          review_permitted: false,
          applies_to_assessor: true
        )

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student3,
          must_review: false,
          review_permitted: false,
          applies_to_assessor: false
        )
      end

      it "includes submissions with should_not_review rules in available submissions" do
        available = service.send(:preload_available_submissions)
        expect(available.map(&:user_id)).to include(student1.id, student2.id, student3.id)
      end

      it "deprioritizes should_not_review submissions but allocates them when no better options exist" do
        result = service.allocate
        expect(result[:success]).to be true
        # With peer_review_count=2 and only 3 submissions (1 regular, 2 should_not_review),
        # it should allocate the regular one first, then one should_not_review as fallback
        expect(result[:assessment_requests].map(&:user_id)).to include(student1.id)
        expect(result[:assessment_requests].size).to eq(2)
      end
    end

    context "when mixing must_review, should_review, and should_not_review rules" do
      before do
        assignment.update!(peer_review_count: 3)
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 3.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 2.days.ago)
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 1.day.ago)

        student4 = student_in_course(active_all: true).user
        @submission4 = assignment.submit_homework(student4, body: "Student4 submission")
        @submission4.update!(submitted_at: 4.days.ago)

        # Must review student1
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true,
          review_permitted: true
        )

        # Should not review student2
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: false,
          review_permitted: false
        )

        # Should review student3
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student3,
          must_review: false,
          review_permitted: true
        )
      end

      it "prioritizes must_review and should_review first, then regular, then should_not_review" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(3)

        allocated_user_ids = result[:assessment_requests].map(&:user_id)

        # Should allocate must_review, should_review, and regular (student4) before should_not_review
        expect(allocated_user_ids).to include(student1.id, student3.id, @submission4.user_id)
        expect(allocated_user_ids).not_to include(student2.id) # should_not_review is lowest priority
      end

      it "includes should_not_review in preload but deprioritizes in selection" do
        available = service.send(:preload_available_submissions)
        # All submissions should be available, including should_not_review
        expect(available.map(&:user_id)).to include(student1.id, student2.id, student3.id, @submission4.user_id)

        result = service.send(:select_submissions_to_allocate, available, 3)
        # Verify priority order: must_review > should_review > regular > should_not_review
        expect(result.first.user_id).to eq(student1.id) # must_review
        expect(result.second.user_id).to eq(student3.id) # should_review
        expect(result.third.user_id).to eq(@submission4.user_id) # regular (not student2 who is should_not_review)
      end
    end

    context "when all available submissions have should_not_review rules" do
      before do
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: false,
          review_permitted: false,
          applies_to_assessor: true
        )

        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: false,
          review_permitted: false,
          applies_to_assessor: false
        )
      end

      it "allocates should_not_review submissions as fallback when no other options exist" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(2)
        expect(result[:assessment_requests].map(&:user_id)).to match_array([student1.id, student2.id])
      end
    end

    context "when mixing must_not_review and should_not_review rules" do
      before do
        assignment.update!(peer_review_count: 2)
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")

        # Must not review student1
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true,
          review_permitted: false
        )

        # Should not review student2
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: false,
          review_permitted: false
        )
      end

      it "excludes must_not_review but includes should_not_review in available submissions" do
        available = service.send(:preload_available_submissions)
        expect(available.map(&:user_id)).not_to include(student1.id) # must_not_review excluded
        expect(available.map(&:user_id)).to include(student2.id, student3.id) # should_not_review and regular included
      end

      it "allocates regular submission first, then should_not_review as fallback, but never must_not_review" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(2)
        expect(result[:assessment_requests].map(&:user_id)).not_to include(student1.id) # must_not_review never allocated
        expect(result[:assessment_requests].map(&:user_id)).to include(student3.id) # regular allocated first
        expect(result[:assessment_requests].map(&:user_id)).to include(student2.id) # should_not_review as fallback
      end
    end

    context "when all four rule types are present" do
      before do
        assignment.update!(peer_review_count: 4)
        assignment.submit_homework(assessor, body: "My submission")
        @submission1 = assignment.submit_homework(student1, body: "Student1 submission")
        @submission1.update!(submitted_at: 4.days.ago)
        @submission2 = assignment.submit_homework(student2, body: "Student2 submission")
        @submission2.update!(submitted_at: 3.days.ago)
        @submission3 = assignment.submit_homework(student3, body: "Student3 submission")
        @submission3.update!(submitted_at: 2.days.ago)

        @student4 = student_in_course(active_all: true).user
        @submission4 = assignment.submit_homework(@student4, body: "Student4 submission")
        @submission4.update!(submitted_at: 1.day.ago)

        @student5 = student_in_course(active_all: true).user
        @submission5 = assignment.submit_homework(@student5, body: "Student5 submission")
        @submission5.update!(submitted_at: 5.days.ago)

        @student6 = student_in_course(active_all: true).user
        @submission6 = assignment.submit_homework(@student6, body: "Student6 submission")
        @submission6.update!(submitted_at: 6.days.ago)

        # Must review student1 (highest priority)
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student1,
          must_review: true,
          review_permitted: true
        )

        # Should review student2 (medium priority)
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student2,
          must_review: false,
          review_permitted: true
        )

        # Must not review student3 (excluded)
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: student3,
          must_review: true,
          review_permitted: false
        )

        # Should not review student4 (excluded)
        AllocationRule.create!(
          course:,
          assignment:,
          assessor:,
          assessee: @student4,
          must_review: false,
          review_permitted: false
        )

        # No rules for student5 and student6 (regular priority)
      end

      it "allocates in correct priority order: must_review > should_review > regular, excludes must_not_review, uses should_not_review as fallback" do
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(4)

        allocated_user_ids = result[:assessment_requests].map(&:user_id)

        # Must review should be allocated (highest priority)
        expect(allocated_user_ids).to include(student1.id)

        # Should review should be allocated (medium priority)
        expect(allocated_user_ids).to include(student2.id)

        # Must not review should NOT be allocated (hard excluded)
        expect(allocated_user_ids).not_to include(student3.id)

        # Regular submissions should fill remaining slots before should_not_review
        expect(allocated_user_ids).to include(@student5.id, @student6.id)

        # Should not review should NOT be allocated when better options exist
        expect(allocated_user_ids).not_to include(@student4.id)
      end

      it "prioritizes correctly: must_review > should_review > regular > should_not_review, excludes must_not_review" do
        available = service.send(:preload_available_submissions)

        # Should exclude must_not_review (hard filter)
        expect(available.map(&:user_id)).not_to include(student3.id)

        # Should include must_review, should_review, regular, and should_not_review (soft filter)
        expect(available.map(&:user_id)).to include(student1.id, student2.id, @student4.id, @student5.id, @student6.id)

        result = service.send(:select_submissions_to_allocate, available, 4)

        # Verify priority order
        expect(result.first.user_id).to eq(student1.id) # must_review first
        expect(result.second.user_id).to eq(student2.id) # should_review second
        # Regular submissions fill remaining slots (sorted by submission date)
        expect(result[2].user_id).to eq(@student6.id) # oldest regular
        expect(result[3].user_id).to eq(@student5.id) # newer regular
        # should_not_review (student4) is not allocated when better options exist
      end

      it "allocates should_not_review as fallback when regular submissions are exhausted" do
        # Request 5 reviews, but only 4 better options exist (1 must_review, 1 should_review, 2 regular)
        assignment.update!(peer_review_count: 5)
        result = service.allocate
        expect(result[:success]).to be true
        expect(result[:assessment_requests].size).to eq(5)

        allocated_user_ids = result[:assessment_requests].map(&:user_id)

        # All better options allocated first
        expect(allocated_user_ids).to include(student1.id, student2.id, @student5.id, @student6.id)

        # should_not_review allocated as fallback since no better options remain
        expect(allocated_user_ids).to include(@student4.id)

        # must_not_review still never allocated
        expect(allocated_user_ids).not_to include(student3.id)
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

  describe "#peer_review_dates_for_assessor caching" do
    before do
      PeerReview::PeerReviewCreatorService.new(
        parent_assignment: assignment,
        points_possible: 5
      ).call

      assignment.reload.peer_review_sub_assignment.update!(
        unlock_at: 1.day.ago,
        lock_at: 1.day.from_now
      )

      assignment.submit_homework(assessor, body: "My submission")
    end

    it "caches the result and only calls peer_review_dates_for_assessor once" do
      allow(service).to receive(:peer_review_dates_for_assessor).and_call_original

      service.send(:peer_review_start_date_for_assessor)
      service.send(:peer_review_start_date_for_assessor)
      service.send(:peer_review_start_date_for_assessor)

      expect(service).to have_received(:peer_review_dates_for_assessor).once
    end

    it "uses the same cached value for both start and lock date methods" do
      allow(service).to receive(:peer_review_dates_for_assessor).and_call_original

      service.send(:peer_review_start_date_for_assessor)
      service.send(:peer_review_lock_date_for_assessor)
      service.send(:peer_review_start_date_for_assessor)
      service.send(:peer_review_lock_date_for_assessor)

      expect(service).to have_received(:peer_review_dates_for_assessor).once
    end

    it "returns consistent values across multiple calls" do
      start_date1 = service.send(:peer_review_start_date_for_assessor)
      start_date2 = service.send(:peer_review_start_date_for_assessor)
      lock_date1 = service.send(:peer_review_lock_date_for_assessor)
      lock_date2 = service.send(:peer_review_lock_date_for_assessor)

      expect(start_date1).to eq(start_date2)
      expect(lock_date1).to eq(lock_date2)
    end
  end

  describe "#preload_available_submissions" do
    context "when peer_review_across_sections is true" do
      let(:section1) { course.course_sections.create!(name: "Section 1") }
      let(:section2) { course.course_sections.create!(name: "Section 2") }
      let(:assessor2) { user_model }
      let(:student4) { user_model }
      let(:student5) { user_model }
      let(:section_assignment) do
        assignment_model(
          course:,
          title: "Section Peer Review Assignment",
          peer_reviews: true,
          peer_review_count: 2,
          peer_review_across_sections: true,
          automatic_peer_reviews: false,
          submission_types: "online_text_entry"
        )
      end

      before do
        course.enroll_student(assessor2, enrollment_state: :active, section: section1)
        course.enroll_student(student4, enrollment_state: :active, section: section1)
        course.enroll_student(student5, enrollment_state: :active, section: section2)

        section_assignment.submit_homework(assessor2, body: "Assessor submission")
        section_assignment.submit_homework(student4, body: "Student4 submission")
        section_assignment.submit_homework(student5, body: "Student5 submission")
      end

      it "includes submissions from all sections" do
        service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
        available = service2.send(:preload_available_submissions)
        expect(available.map(&:user_id)).to match_array([student4.id, student5.id])
      end
    end

    context "when peer_review_across_sections is false" do
      let(:section1) { course.course_sections.create!(name: "Section 1") }
      let(:section2) { course.course_sections.create!(name: "Section 2") }
      let(:assessor2) { user_model }
      let(:student4) { user_model }
      let(:student5) { user_model }
      let(:student6) { user_model }
      let(:section_assignment) do
        assignment_model(
          course:,
          title: "Section Peer Review Assignment",
          peer_reviews: true,
          peer_review_count: 2,
          peer_review_across_sections: false,
          automatic_peer_reviews: false,
          submission_types: "online_text_entry"
        )
      end

      before do
        course.enroll_student(assessor2, enrollment_state: :active, section: section1)
        course.enroll_student(student4, enrollment_state: :active, section: section1)

        course.enroll_student(student5, enrollment_state: :active, section: section2)
        course.enroll_student(student6, enrollment_state: :active, section: section2)

        section_assignment.submit_homework(assessor2, body: "Assessor submission")
        section_assignment.submit_homework(student4, body: "Student4 submission")
        section_assignment.submit_homework(student5, body: "Student5 submission")
        section_assignment.submit_homework(student6, body: "Student6 submission")
      end

      it "only includes submissions from the same section as assessor" do
        service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
        available = service2.send(:preload_available_submissions)
        expect(available.map(&:user_id)).to eq([student4.id])
      end

      it "excludes submissions from different sections" do
        service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
        available = service2.send(:preload_available_submissions)
        expect(available.map(&:user_id)).not_to include(student5.id, student6.id)
      end

      context "when assessor is in multiple sections" do
        before do
          course.enroll_student(assessor2, enrollment_state: :active, section: section2, allow_multiple_enrollments: true)
        end

        it "includes submissions from all assessor's sections" do
          service2 = described_class.new(assignment: section_assignment, assessor: assessor2)
          available = service2.send(:preload_available_submissions)
          expect(available.map(&:user_id)).to match_array([student4.id, student5.id, student6.id])
        end
      end
    end

    context "when filtering submissions by actual work submitted" do
      before do
        assignment.submit_homework(assessor, body: "Assessor submission")
      end

      it "includes submitted submissions with actual work" do
        submission = assignment.submit_homework(student1, body: "Student1 submission")
        submission.update!(workflow_state: "submitted")

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).to include(submission.id)
      end

      it "includes pending_review submissions with actual work" do
        submission = assignment.submit_homework(student1, body: "Student1 submission")
        submission.update!(workflow_state: "pending_review")

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).to include(submission.id)
      end

      it "includes graded submissions with actual work" do
        submission = assignment.submit_homework(student1, body: "Student1 submission")
        assignment.grade_student(student1, grader: course.teachers.first, score: 10)

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).to include(submission.id)
      end

      it "excludes graded submissions without actual submission_type" do
        submission = assignment.submissions.find_by(user: student1)
        submission.update!(workflow_state: "graded", score: 10, submission_type: nil)

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).not_to include(submission.id)
      end

      it "excludes deleted submissions" do
        submission = assignment.submit_homework(student1, body: "Student1 submission")
        submission.update!(workflow_state: "deleted")

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).not_to include(submission.id)
      end

      it "excludes unsubmitted submissions without submission_type" do
        submission = assignment.submissions.find_by(user: student1)
        submission.update!(workflow_state: "unsubmitted", submission_type: nil)

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).not_to include(submission.id)
      end

      it "excludes the assessor's own submission" do
        assessor_submission = assignment.submissions.find_by(user: assessor)

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).not_to include(assessor_submission.id)
      end

      it "excludes submissions already assigned to the assessor" do
        submission = assignment.submit_homework(student1, body: "Student1 submission")
        assignment.assign_peer_review(assessor, student1)

        available = service.send(:preload_available_submissions)
        expect(available.map(&:id)).not_to include(submission.id)
      end
    end
  end
end
