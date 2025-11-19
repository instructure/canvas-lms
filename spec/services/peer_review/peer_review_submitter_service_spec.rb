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

RSpec.describe PeerReview::PeerReviewSubmitterService do
  let(:course) { course_model(name: "Course with Peer Review Assignment") }
  let(:assessor) { user_model(name: "Assessor User") }
  let(:student1) { user_model(name: "Student 1") }
  let(:student2) { user_model(name: "Student 2") }

  let(:parent_assignment) do
    assignment_model(
      course:,
      title: "Parent Assignment",
      peer_review_count: 2,
      peer_reviews: true
    )
  end

  let(:peer_review_sub_assignment) do
    PeerReviewSubAssignment.create!(
      parent_assignment:,
      peer_review_count: 2
    )
  end

  let(:earliest_time) { 3.hours.ago }
  let(:later_time) { 1.hour.ago }

  let(:service) { described_class.new(parent_assignment:, assessor:) }

  before do
    course.enable_feature!(:peer_review_allocation_and_grading)
    create_enrollment(course, assessor, enrollment_state: "active")
    create_enrollment(course, student1, enrollment_state: "active")
    create_enrollment(course, student2, enrollment_state: "active")
  end

  def create_assessment_request(user:, submission:, assessor:, workflow_state: "completed")
    AssessmentRequest.create!(
      user:,
      asset: submission,
      assessor_asset: submission_model(assignment: parent_assignment, user: assessor),
      assessor:,
      workflow_state:
    )
  end

  def create_submission_comment(submission:, author:, created_at:, comment: "Test comment")
    SubmissionComment.create!(
      submission:,
      author:,
      comment:,
      created_at:
    )
  end

  def create_rubric_assessment(rubric:, user:, assessor:, artifact:, created_at:)
    RubricAssessment.create!(
      rubric:,
      user:,
      assessor:,
      artifact:,
      assessment_type: "peer_review",
      created_at:
    )
  end

  def setup_basic_assessment_requests
    @submission1 = submission_model(assignment: parent_assignment, user: student1)
    @submission2 = submission_model(assignment: parent_assignment, user: student2)

    @assessment_request1 = create_assessment_request(
      user: student1,
      submission: @submission1,
      assessor:
    )
    @assessment_request2 = create_assessment_request(
      user: student2,
      submission: @submission2,
      assessor:
    )
  end

  def setup_rubric_assessments(first_create_time: earliest_time, second_create_time: later_time)
    @rubric = rubric_model(context: course)
    parent_assignment.update!(rubric: @rubric)

    @rubric_assessment1 = create_rubric_assessment(
      rubric: @rubric,
      user: student1,
      assessor:,
      artifact: @submission1,
      created_at: first_create_time
    )
    @rubric_assessment2 = create_rubric_assessment(
      rubric: @rubric,
      user: student2,
      assessor:,
      artifact: @submission2,
      created_at: second_create_time
    )

    @assessment_request1.update!(rubric_assessment: @rubric_assessment1)
    @assessment_request2.update!(rubric_assessment: @rubric_assessment2)
  end

  def setup_submission_comments(first_create_time: earliest_time, second_create_time: later_time)
    parent_assignment.update!(rubric: nil)

    @comment1 = create_submission_comment(
      submission: @submission1,
      author: assessor,
      comment: "Good work!",
      created_at: first_create_time
    )
    @comment2 = create_submission_comment(
      submission: @submission2,
      author: assessor,
      comment: "Needs improvement",
      created_at: second_create_time
    )

    @assessment_request1.submission_comments << @comment1
    @assessment_request2.submission_comments << @comment2
  end

  describe "#initialize" do
    it "inherits from ApplicationService" do
      expect(described_class.superclass).to eq(ApplicationService)
    end

    it "accepts parent_assignment and assessor parameters" do
      expect { service }.not_to raise_error
    end

    it "sets instance variables correctly" do
      expect(service.instance_variable_get(:@parent_assignment)).to eq(parent_assignment)
      expect(service.instance_variable_get(:@assessor)).to eq(assessor)
    end

    it "can be initialized with nil parameters" do
      service_with_nils = described_class.new(parent_assignment: nil, assessor: nil)
      expect(service_with_nils).to be_a(described_class)
    end
  end

  describe "#call" do
    context "when all conditions are met" do
      before do
        peer_review_sub_assignment
        setup_basic_assessment_requests
      end

      it "creates a peer review submission" do
        result = service.call
        expect(result).to be_a(Submission)
        expect(result.assignment).to eq(peer_review_sub_assignment)
        expect(result.user).to eq(assessor)
      end

      it "returns the submission" do
        result = service.call
        expect(result).to be_a(Submission)
      end

      context "with rubric assessments" do
        before do
          setup_rubric_assessments
        end

        it "uses the earliest rubric assessment time" do
          result = service.call
          expect(result.submitted_at).not_to be_nil
          expect(result.submitted_at).to eq earliest_time
        end

        it "ignores deleted rubric assessments" do
          @rubric_assessment1.destroy

          result = service.call
          expect(result.submitted_at).not_to be_nil
          expect(result.submitted_at).to eq later_time
        end
      end

      context "with submission comments" do
        before do
          setup_submission_comments
        end

        it "uses the earliest submission comment time" do
          result = service.call

          expect(result.submitted_at).not_to be_nil
          expect(result.submitted_at).to eq earliest_time
        end

        it "ignores deleted submission comments" do
          @comment1.destroy

          result = service.call
          expect(result.submitted_at).not_to be_nil
          expect(result.submitted_at).to eq later_time
        end
      end
    end

    context "when peer review submission is not supported" do
      it "returns nil when parent assignment does not exist" do
        service_without_assignment = described_class.new(parent_assignment: nil, assessor:)
        expect(service_without_assignment.call).to be_nil
      end

      it "returns nil when parent assignment is deleted" do
        parent_assignment.update!(workflow_state: "deleted")
        expect(service.call).to be_nil
      end

      it "returns nil when peer review sub assignment does not exist" do
        expect(service.call).to be_nil
      end

      it "returns nil when peer review sub assignment is deleted" do
        peer_review_sub_assignment.update!(workflow_state: "deleted")
        expect(service.call).to be_nil
      end

      it "returns nil when assessor does not exist" do
        service_without_assessor = described_class.new(parent_assignment:, assessor: nil)
        expect(service_without_assessor.call).to be_nil
      end

      it "returns nil when assessor is deleted" do
        assessor.update!(workflow_state: "deleted")
        expect(service.call).to be_nil
      end

      it "returns nil when feature is disabled" do
        course.disable_feature!(:peer_review_allocation_and_grading)
        expect(service.call).to be_nil
      end
    end

    context "when peer review is already submitted" do
      before do
        peer_review_sub_assignment
        submission_model(
          assignment: peer_review_sub_assignment,
          user: assessor,
          workflow_state: "submitted"
        )
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end
    end

    context "when required peer reviews are not met" do
      before do
        peer_review_sub_assignment

        submission1 = submission_model(assignment: parent_assignment, user: student1)
        create_assessment_request(
          user: student1,
          submission: submission1,
          assessor:
        )
      end

      it "returns nil" do
        expect(service.call).to be_nil
      end
    end
  end

  describe "private methods" do
    describe "#parent_assignment_active?" do
      it "returns true when parent assignment is present and active" do
        expect(service.send(:parent_assignment_active?)).to be true
      end

      it "returns false when parent assignment is nil" do
        service.instance_variable_set(:@parent_assignment, nil)
        expect(service.send(:parent_assignment_active?)).to be false
      end

      it "returns false when parent assignment is deleted" do
        parent_assignment.update!(workflow_state: "deleted")
        expect(service.send(:parent_assignment_active?)).to be false
      end
    end

    describe "#peer_review_sub_assignment_active?" do
      it "returns true when peer review sub assignment is present and active" do
        peer_review_sub_assignment
        expect(service.send(:peer_review_sub_assignment_active?)).to be true
      end

      it "returns false when peer review sub assignment is nil" do
        expect(service.send(:peer_review_sub_assignment_active?)).to be false
      end

      it "returns false when peer review sub assignment is deleted" do
        peer_review_sub_assignment.update!(workflow_state: "deleted")
        expect(service.send(:peer_review_sub_assignment_active?)).to be false
      end
    end

    describe "#peer_reviews_enabled?" do
      it "returns true when parent assignment is present and has peer reviews enabled" do
        expect(service.send(:peer_reviews_enabled?)).to be true
      end

      it "returns false when parent assignment has peer reviews disabled" do
        parent_assignment.update!(peer_reviews: false)
        expect(service.send(:peer_reviews_enabled?)).to be false
      end

      it "returns false when parent assignment is nil" do
        service.instance_variable_set(:@parent_assignment, nil)
        expect(service.send(:peer_reviews_enabled?)).to be false
      end
    end

    describe "#assessor_active?" do
      it "returns true when assessor is present and not deleted" do
        expect(service.send(:assessor_active?)).to be true
      end

      it "returns false when assessor is nil" do
        service.instance_variable_set(:@assessor, nil)
        expect(service.send(:assessor_active?)).to be false
      end

      it "returns false when assessor is deleted" do
        assessor.update!(workflow_state: "deleted")
        expect(service.send(:assessor_active?)).to be false
      end
    end

    describe "#peer_review_sub_assignment" do
      it "returns the associated peer review sub assignment" do
        peer_review_sub_assignment
        result = service.send(:peer_review_sub_assignment)
        expect(result).to eq(peer_review_sub_assignment)
      end

      it "memoizes the result" do
        peer_review_sub_assignment
        first_call = service.send(:peer_review_sub_assignment)
        second_call = service.send(:peer_review_sub_assignment)
        expect(first_call).to be(second_call)
      end

      it "returns nil when no peer review sub assignment exists" do
        result = service.send(:peer_review_sub_assignment)
        expect(result).to be_nil
      end
    end

    describe "#feature_enabled?" do
      it "returns true when feature is enabled" do
        expect(service.send(:feature_enabled?)).to be true
      end

      it "returns false when feature is disabled" do
        course.disable_feature!(:peer_review_allocation_and_grading)
        expect(service.send(:feature_enabled?)).to be false
      end
    end

    describe "#peer_review_submission_supported?" do
      it "returns true when all conditions are met" do
        peer_review_sub_assignment
        expect(service.send(:peer_review_submission_supported?)).to be true
      end

      it "returns false when parent assignment does not exist" do
        service.instance_variable_set(:@parent_assignment, nil)
        expect(service.send(:peer_review_submission_supported?)).to be false
      end

      it "returns false when parent assignment is not active" do
        parent_assignment.update!(workflow_state: "deleted")
        expect(service.send(:peer_review_submission_supported?)).to be false
      end

      it "returns false when parent assignment does not have peer reviews enabled" do
        parent_assignment.update!(peer_reviews: false)
        expect(service.send(:peer_review_submission_supported?)).to be false
      end

      it "returns false when peer review sub assignment does not exist" do
        expect(service.send(:peer_review_submission_supported?)).to be false
      end

      it "returns false when peer review sub assignment is not active" do
        peer_review_sub_assignment.update!(workflow_state: "deleted")
        expect(service.send(:peer_review_submission_supported?)).to be false
      end

      it "returns false when assessor is not active" do
        service.instance_variable_set(:@assessor, nil)
        expect(service.send(:peer_review_submission_supported?)).to be false
      end

      it "returns false when feature is disabled" do
        course.disable_feature!(:peer_review_allocation_and_grading)
        expect(service.send(:peer_review_submission_supported?)).to be false
      end
    end

    describe "#peer_review_unsubmitted?" do
      before do
        peer_review_sub_assignment
      end

      it "returns false when a submitted submission exists" do
        peer_review_sub_assignment.submit_homework(
          assessor,
          submission_type: "online_text_entry",
          body: "Peer reviews submitted"
        )
        expect(service.send(:peer_review_unsubmitted?)).to be false
      end

      it "returns true when no submission exists" do
        expect(service.send(:peer_review_unsubmitted?)).to be true
      end

      it "returns true when submission exists but is not submitted" do
        submission_model(
          assignment: peer_review_sub_assignment,
          user: assessor,
          workflow_state: "unsubmitted"
        )
        expect(service.send(:peer_review_unsubmitted?)).to be true
      end

      it "returns true when submission is deleted" do
        sub = submission_model(
          assignment: peer_review_sub_assignment,
          user: assessor,
          workflow_state: "submitted"
        )
        sub.destroy
        expect(service.send(:peer_review_unsubmitted?)).to be_truthy
      end
    end

    describe "#completed_assessment_requests" do
      before do
        @submission1 = submission_model(assignment: parent_assignment, user: student1)
        @submission2 = submission_model(assignment: parent_assignment, user: student2)
      end

      it "returns completed assessment requests for the assessor and assignment" do
        assessment_request1 = create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor:
        )
        assessment_request2 = create_assessment_request(
          user: student2,
          submission: @submission2,
          assessor:
        )

        result = service.send(:completed_assessment_requests)
        expect(result).to include(assessment_request1, assessment_request2)
      end

      it "excludes incomplete assessment requests" do
        create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor:,
          workflow_state: "assigned"
        )

        result = service.send(:completed_assessment_requests)
        expect(result).to be_empty
      end

      it "excludes assessment requests for different assessors" do
        other_assessor = user_model
        create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor: other_assessor
        )

        result = service.send(:completed_assessment_requests)
        expect(result).to be_empty
      end

      it "excludes assessment requests for different assignments" do
        other_assignment = assignment_model(course:)
        other_submission = submission_model(assignment: other_assignment, user: student1)
        AssessmentRequest.create!(
          user: student1,
          asset: other_submission,
          assessor_asset: submission_model(assignment: other_assignment, user: assessor),
          assessor:,
          workflow_state: "completed"
        )

        result = service.send(:completed_assessment_requests)
        expect(result).to be_empty
      end

      it "memoizes the result" do
        first_call = service.send(:completed_assessment_requests)
        second_call = service.send(:completed_assessment_requests)
        expect(first_call).to be(second_call)
      end
    end

    describe "#required_peer_reviews_met?" do
      before do
        peer_review_sub_assignment
        @submission1 = submission_model(assignment: parent_assignment, user: student1)
        @submission2 = submission_model(assignment: parent_assignment, user: student2)
      end

      it "returns true when required number of peer reviews is met" do
        create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor:
        )
        create_assessment_request(
          user: student2,
          submission: @submission2,
          assessor:
        )

        expect(service.send(:required_peer_reviews_met?)).to be true
      end

      it "returns false when required number of peer reviews is not met" do
        create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor:
        )

        expect(service.send(:required_peer_reviews_met?)).to be false
      end

      it "returns true when peer_review_count is nil or 0" do
        peer_review_sub_assignment.update!(peer_review_count: nil)
        expect(service.send(:required_peer_reviews_met?)).to be true

        peer_review_sub_assignment.update!(peer_review_count: 0)
        expect(service.send(:required_peer_reviews_met?)).to be true
      end

      it "returns true when more than required peer reviews are completed" do
        student3 = user_model
        create_enrollment(course, student3, enrollment_state: "active")
        submission3 = submission_model(assignment: parent_assignment, user: student3)

        create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor:
        )
        create_assessment_request(
          user: student2,
          submission: @submission2,
          assessor:
        )
        create_assessment_request(
          user: student3,
          submission: submission3,
          assessor:
        )

        expect(service.send(:required_peer_reviews_met?)).to be true
      end
    end

    describe "#peer_reviews_submitted_at" do
      before do
        @submission1 = submission_model(assignment: parent_assignment, user: student1)
        @submission2 = submission_model(assignment: parent_assignment, user: student2)
        @assessment_request1 = create_assessment_request(
          user: student1,
          submission: @submission1,
          assessor:
        )
        @assessment_request2 = create_assessment_request(
          user: student2,
          submission: @submission2,
          assessor:
        )
      end

      it "returns nil when no assessment requests exist" do
        service.instance_variable_set(:@completed_assessment_requests, AssessmentRequest.none)
        expect(service.send(:peer_reviews_submitted_at)).to be_nil
      end

      context "with rubric assessments" do
        before do
          @rubric = rubric_model(context: course)
          parent_assignment.update!(rubric: @rubric)

          @rubric_assessment1 = create_rubric_assessment(
            rubric: @rubric,
            user: student1,
            assessor:,
            artifact: @submission1,
            created_at: earliest_time
          )
          @rubric_assessment2 = create_rubric_assessment(
            rubric: @rubric,
            user: student2,
            assessor:,
            artifact: @submission2,
            created_at: later_time
          )

          @assessment_request1.update!(rubric_assessment: @rubric_assessment1)
          @assessment_request2.update!(rubric_assessment: @rubric_assessment2)
        end

        it "returns the earliest rubric assessment creation time" do
          result = service.send(:peer_reviews_submitted_at)
          expect(result).to eq(@rubric_assessment1.created_at)
        end

        it "ignores deleted rubric assessments" do
          @rubric_assessment1.destroy

          result = service.send(:peer_reviews_submitted_at)
          expect(result).not_to be_nil
          expect(result).to eq(@rubric_assessment2.created_at)
        end
      end

      context "with submission comments" do
        before do
          parent_assignment.update!(rubric: nil)

          @comment1 = create_submission_comment(
            submission: @submission1,
            author: assessor,
            comment: "Good work!",
            created_at: earliest_time
          )
          @comment2 = create_submission_comment(
            submission: @submission2,
            author: assessor,
            comment: "Needs improvement",
            created_at: later_time
          )

          @assessment_request1.submission_comments << @comment1
          @assessment_request2.submission_comments << @comment2
        end

        it "returns the earliest submission comment creation time" do
          result = service.send(:peer_reviews_submitted_at)
          expect(result).to eq(@comment1.created_at)
        end

        it "ignores deleted submission comments" do
          @comment1.destroy

          result = service.send(:peer_reviews_submitted_at)
          expect(result).not_to be_nil
          expect(result).to eq(@comment2.created_at)
        end
      end
    end

    describe "#create_peer_review_submission" do
      before do
        peer_review_sub_assignment
      end

      it "calls submit_homework on the peer review sub assignment" do
        submitted_time = 1.hour.ago
        allow(service).to receive(:peer_reviews_submitted_at).and_return(submitted_time)

        expect(peer_review_sub_assignment).to receive(:submit_homework).with(
          assessor,
          hash_including(
            submission_type: PeerReview::PeerReviewSubmitterService::PEER_REVIEW_SUBMISSION_TYPE,
            body: PeerReview::PeerReviewSubmitterService::PEER_REVIEW_SUBMISSION_BODY,
            submitted_at: submitted_time
          )
        )

        service.send(:create_peer_review_submission, assessor)
      end

      it "returns the submission when successful" do
        submitted_time = 1.hour.ago
        allow(service).to receive(:peer_reviews_submitted_at).and_return(submitted_time)

        result = service.send(:create_peer_review_submission, assessor)
        expect(result).to be_a(Submission)
        expect(result.assignment).to eq(peer_review_sub_assignment)
        expect(result.user).to eq(assessor)
      end
    end
  end
end
