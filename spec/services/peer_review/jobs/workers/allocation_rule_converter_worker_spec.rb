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

describe PeerReview::Jobs::Workers::AllocationRuleConverterWorker do
  let(:course) { course_model }
  let(:assignment) { assignment_model(course:, peer_reviews: true) }
  let(:assessor) { user_model }
  let(:assessee) { user_model }
  let(:assessor2) { user_model }
  let(:assessee2) { user_model }

  before do
    course.enroll_student(assessor, enrollment_state: "active")
    course.enroll_student(assessee, enrollment_state: "active")
    course.enroll_student(assessor2, enrollment_state: "active")
    course.enroll_student(assessee2, enrollment_state: "active")
  end

  describe ".start_job" do
    context "with valid parameters" do
      it "creates a Progress record with assignment as context" do
        expect do
          described_class.start_job(assignment, "AllocationRule")
        end.to change(Progress, :count).by(1)

        progress = Progress.last
        expect(progress.context).to eq(assignment)
        expect(progress.tag).to eq("peer_review_allocation_conversion")
      end

      it "accepts 'AllocationRule' as type" do
        expect do
          described_class.start_job(assignment, "AllocationRule")
        end.not_to raise_error
      end

      it "accepts 'AssessmentRequest' as type" do
        course.enable_feature!(:peer_review_allocation_and_grading)
        PeerReview::PeerReviewCreatorService.call(parent_assignment: assignment)
        assignment.reload

        expect do
          described_class.start_job(assignment, "AssessmentRequest")
        end.not_to raise_error
      end

      it "accepts should_delete parameter" do
        expect do
          described_class.start_job(assignment, "AllocationRule", should_delete: true)
        end.not_to raise_error
      end
    end

    context "with invalid type parameter" do
      it "raises ArgumentError for invalid type" do
        expect do
          described_class.start_job(assignment, "InvalidType")
        end.to raise_error(ArgumentError, "Type must be 'AllocationRule' or 'AssessmentRequest'")
      end

      it "raises ArgumentError for nil type" do
        expect do
          described_class.start_job(assignment, nil)
        end.to raise_error(ArgumentError, "Type must be 'AllocationRule' or 'AssessmentRequest'")
      end
    end

    context "feature flag validation" do
      context "when converting AssessmentRequests" do
        it "raises error if feature flag is not enabled" do
          course.disable_feature!(:peer_review_allocation_and_grading)

          expect do
            described_class.start_job(assignment, "AssessmentRequest")
          end.to raise_error(ArgumentError, /Feature flag peer_review_allocation_and_grading must be enabled/)
        end

        it "raises error if PeerReviewSubAssignment does not exist" do
          course.enable_feature!(:peer_review_allocation_and_grading)

          expect do
            described_class.start_job(assignment, "AssessmentRequest")
          end.to raise_error(ArgumentError, "PeerReviewSubAssignment must exist before converting AssessmentRequests")
        end

        it "succeeds when feature flag is enabled and PeerReviewSubAssignment exists" do
          course.enable_feature!(:peer_review_allocation_and_grading)
          PeerReview::PeerReviewCreatorService.call(parent_assignment: assignment)
          assignment.reload

          expect do
            described_class.start_job(assignment, "AssessmentRequest")
          end.not_to raise_error
        end
      end

      context "when converting AllocationRules" do
        it "raises error if feature flag is enabled" do
          course.enable_feature!(:peer_review_allocation_and_grading)

          expect do
            described_class.start_job(assignment, "AllocationRule")
          end.to raise_error(ArgumentError, /Feature flag peer_review_allocation_and_grading must be disabled/)
        end

        it "raises error if PeerReviewSubAssignment exists" do
          course.disable_feature!(:peer_review_allocation_and_grading)
          PeerReviewSubAssignment.create!(parent_assignment: assignment)

          expect do
            described_class.start_job(assignment, "AllocationRule")
          end.to raise_error(ArgumentError, "PeerReviewSubAssignment must not exist when converting AllocationRules")
        end

        it "succeeds when feature flag is disabled and PeerReviewSubAssignment does not exist" do
          course.disable_feature!(:peer_review_allocation_and_grading)

          expect do
            described_class.start_job(assignment, "AllocationRule")
          end.not_to raise_error
        end
      end
    end
  end

  describe ".perform" do
    context "converting AllocationRules to AssessmentRequests" do
      before do
        course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "converts allocation rules and updates progress" do
        AllocationRule.create!(assessor:, assessee:, assignment:, course:, must_review: true, review_permitted: true)
        AllocationRule.create!(assessor: assessor2, assessee: assessee2, assignment:, course:, must_review: true, review_permitted: true)

        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AllocationRule", false)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")
        expect(job_progress.completion).to eq(100)

        expect(AllocationRule.active.count).to eq(0)
        expect(AssessmentRequest.for_assignment(assignment.id).count).to eq(2)
      end

      it "cleans up leftover allocation rules after conversion" do
        # Create some "must review" rules
        AllocationRule.create!(assessor:, assessee:, assignment:, course:, must_review: true, review_permitted: true)
        # Create some "should review" rules (not converted)
        AllocationRule.create!(assessor: assessor2, assessee: assessee2, assignment:, course:, must_review: false, review_permitted: true)

        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AllocationRule", false)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")

        # All allocation rules should be deleted (including the "should review" one)
        expect(AllocationRule.active.count).to eq(0)
      end

      it "processes resources in batches of 25" do
        # Create 26 allocation rules (enough to trigger 2 batches: 25 + 1)
        26.times do
          user1 = user_model
          user2 = user_model
          course.enroll_student(user1, enrollment_state: "active")
          course.enroll_student(user2, enrollment_state: "active")
          AllocationRule.create!(assessor: user1, assessee: user2, assignment:, course:, must_review: true, review_permitted: true)
        end

        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        # Should call convert_resources multiple times (for different batches)
        expect(described_class).to receive(:convert_resources).at_least(:twice).and_call_original

        described_class.perform(assignment, "AllocationRule", false)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")
      end
    end

    context "converting AssessmentRequests to AllocationRules" do
      before do
        course.enable_feature!(:peer_review_allocation_and_grading)
        PeerReview::PeerReviewCreatorService.call(parent_assignment: assignment)
        assignment.reload
      end

      it "converts assessment requests and updates progress" do
        peer_review_sub = assignment.peer_review_sub_assignment

        # Create legacy assessment requests (before peer review sub assignment)
        ar1 = assignment.assign_peer_review(assessor, assessee)
        ar1.update_column(:created_at, peer_review_sub.created_at - 1.day)

        ar2 = assignment.assign_peer_review(assessor2, assessee2)
        ar2.update_column(:created_at, peer_review_sub.created_at - 1.day)

        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AssessmentRequest", false)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")
        expect(job_progress.completion).to eq(100)

        expect(AssessmentRequest.for_assignment(assignment.id).incomplete.count).to eq(0)
        expect(AllocationRule.active.count).to eq(2)
      end

      it "only converts legacy assessment requests based on timestamp" do
        # Create peer review sub assignment
        peer_review_sub = assignment.peer_review_sub_assignment

        # Create an old assessment request (before peer review sub assignment)
        old_ar = assignment.assign_peer_review(assessor, assessee)
        old_ar.update_column(:created_at, peer_review_sub.created_at - 1.day)

        # Create a new assessment request (after peer review sub assignment).
        # This can happen when a student starts their peer review and is allocated reviews.
        new_ar = assignment.assign_peer_review(assessor2, assessee2)
        new_ar.update_column(:created_at, peer_review_sub.created_at + 1.day)

        Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AssessmentRequest", false)

        # Only the old assessment request should be converted
        expect(AllocationRule.active.count).to eq(1)
        expect(AssessmentRequest.for_assignment(assignment.id).incomplete.count).to eq(1)
        expect { old_ar.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { new_ar.reload }.not_to raise_error
      end
    end

    context "deleting AllocationRules" do
      before do
        course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "deletes all allocation rules and updates progress" do
        AllocationRule.create!(assessor:, assessee:, assignment:, course:, must_review: true, review_permitted: true)
        AllocationRule.create!(assessor: assessor2, assessee: assessee2, assignment:, course:, must_review: false, review_permitted: true)

        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AllocationRule", true)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")
        expect(job_progress.completion).to eq(100)

        # All allocation rules should be deleted
        expect(AllocationRule.active.count).to eq(0)
      end
    end

    context "deleting AssessmentRequests" do
      before do
        course.enable_feature!(:peer_review_allocation_and_grading)
        PeerReview::PeerReviewCreatorService.call(parent_assignment: assignment)
        assignment.reload
      end

      it "deletes legacy assessment requests and updates progress" do
        peer_review_sub = assignment.peer_review_sub_assignment

        old_ar1 = assignment.assign_peer_review(assessor, assessee)
        old_ar1.update_column(:created_at, peer_review_sub.created_at - 1.day)

        old_ar2 = assignment.assign_peer_review(assessor2, assessee2)
        old_ar2.update_column(:created_at, peer_review_sub.created_at - 2.days)

        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AssessmentRequest", true)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")

        expect { old_ar1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { old_ar2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with empty resource list" do
      before do
        course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "completes successfully with no resources to process" do
        job_progress = Progress.create!(context: assignment, tag: "peer_review_allocation_conversion")

        described_class.perform(assignment, "AllocationRule", false)

        job_progress.reload
        expect(job_progress.workflow_state).to eq("completed")
        expect(job_progress.completion).to eq(100)
      end
    end

    context "error handling" do
      before do
        course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "raises error if no progress found" do
        expect do
          described_class.perform(assignment, "AllocationRule", false)
        end.to raise_error(/No job progress found/)
      end
    end
  end
end
