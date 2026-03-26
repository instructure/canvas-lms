# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

RSpec.describe PeerReview::SubmissionUpdaterService do
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
    peer_review_model(parent_assignment:)
    parent_assignment.reload.peer_review_sub_assignment
  end

  let(:service) do
    PeerReview::SubmissionUpdaterService.new(
      parent_assignment:,
      assessor:
    )
  end

  before do
    course.enable_feature!(:peer_review_allocation_and_grading)
    create_enrollment(course, assessor, enrollment_state: "active")
    create_enrollment(course, student1, enrollment_state: "active")
    create_enrollment(course, student2, enrollment_state: "active")
  end

  def create_submission_for(user)
    submission_model(assignment: parent_assignment, user:)
  end

  def create_peer_review_comment_for(assessment_request:, submission:, assessor: nil, created_at: Time.zone.now)
    assessor ||= self.assessor
    SubmissionComment.create!(
      submission:,
      author: assessor,
      comment: "peer review feedback",
      created_at:,
      draft: false,
      workflow_state: "active",
      assessment_request_id: assessment_request.id
    )
    assessment_request.comment_added
    assessment_request.save!
  end

  def create_assessment_request(user:, submission:, assessor: nil)
    assessor ||= self.assessor
    assessor_asset = parent_assignment.submissions.find_by(user_id: assessor.id) ||
                     submission_model(assignment: parent_assignment, user: assessor)

    AssessmentRequest.create!(
      user:,
      asset: submission,
      assessor_asset:,
      assessor:,
      peer_review_sub_assignment_id: peer_review_sub_assignment.id
    )
  end

  def completed_assessment_requests(assignment: parent_assignment)
    AssessmentRequest.complete
                     .joins(:submission)
                     .where(
                       assessor_id: assessor.id,
                       submissions: { assignment_id: assignment.id }
                     ).count
  end

  def create_submitted_peer_review_submission(assignment: parent_assignment)
    required_count = assignment.peer_review_count
    existing_completed = completed_assessment_requests(assignment:)

    # Create additional assessment requests to meet the threshold
    (required_count - existing_completed).times do |i|
      student = user_model(name: "Review Student #{existing_completed + i + 1}")
      create_enrollment(course, student, enrollment_state: "active")
      submission = create_submission_for(student)

      assessment_request = create_assessment_request(
        user: student,
        submission:
      )

      create_peer_review_comment_for(
        assessment_request:,
        submission:
      )
    end

    peer_review_sub_assignment.submissions.active.find_by(user_id: assessor.id)
  end

  def get_assessment_request_for_assessor(assignment: parent_assignment)
    sub_assignment = assignment.peer_review_sub_assignment
    return nil unless sub_assignment

    AssessmentRequest.complete
                     .where(
                       assessor_id: assessor.id,
                       peer_review_sub_assignment_id: sub_assignment.id
                     )
                     .first
  end

  describe "#call" do
    context "when peer reviews fall below threshold" do
      it "unsubmits the submission" do
        peer_review_submission = create_submitted_peer_review_submission
        expect(peer_review_submission.workflow_state).to eq("submitted")

        # When assessment request is destroyed, the after_destroy callback calls
        # SubmissionUpdaterService, which unsubmits the submission
        request = get_assessment_request_for_assessor
        request.destroy

        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("unsubmitted")
      end

      it "returns the submission" do
        peer_review_sub_assignment
        peer_review_submission = create_submitted_peer_review_submission
        original_submission_id = peer_review_submission.id

        request = get_assessment_request_for_assessor
        request.destroy

        # Verify the same submission was unsubmitted (not a new one)
        peer_review_submission.reload
        expect(peer_review_submission.id).to eq(original_submission_id)
        expect(peer_review_submission.workflow_state).to eq("unsubmitted")
      end
    end

    context "when peer reviews meet threshold" do
      it "does not unsubmit the submission" do
        student3 = user_model(name: "Student 3")
        create_enrollment(course, student3, enrollment_state: "active")

        submission3 = create_submission_for(student3)
        create_assessment_request(user: student3, submission: submission3)
        peer_review_submission = create_submitted_peer_review_submission

        expect(peer_review_submission.workflow_state).to eq("submitted")

        result = service.call

        expect(result).to be_nil
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
      end

      it "returns nil when no timestamp update is needed" do
        peer_review_submission = create_submitted_peer_review_submission

        expect(peer_review_submission.workflow_state).to eq("submitted")
        original_submitted_at = peer_review_submission.submitted_at

        result = service.call

        expect(result).to be_nil
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
        expect(peer_review_submission.submitted_at).to eq(original_submitted_at)
      end

      it "returns the submission when timestamp update is needed" do
        peer_review_submission = create_submitted_peer_review_submission

        expect(peer_review_submission.workflow_state).to eq("submitted")
        peer_review_submission.update!(submitted_at: 5.days.ago)

        result = service.call

        expect(result).to be_a(Submission)
        expect(result.id).to eq(peer_review_submission.id)
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
        expect(peer_review_submission.submitted_at).not_to eq(5.days.ago)
      end
    end

    context "when peer_review_sub_assignment does not exist" do
      it "returns nil" do
        assignment_without_peer_review_sub = assignment_model(
          course:,
          title: "Assignment Without Peer Review Sub",
          peer_reviews: true
        )

        service_no_sub = PeerReview::SubmissionUpdaterService.new(
          parent_assignment: assignment_without_peer_review_sub,
          assessor:
        )

        result = service_no_sub.call

        expect(result).to be_nil
      end
    end

    context "when peer_review_sub_assignment is destroyed" do
      it "returns nil and does not unsubmit" do
        peer_review_sub_assignment
        peer_review_submission = create_submitted_peer_review_submission

        expect(peer_review_submission.workflow_state).to eq("submitted")

        peer_review_sub_assignment.destroy

        result = service.call

        expect(result).to be_nil
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
      end
    end

    context "when assessor is deleted" do
      it "returns nil and does not unsubmit" do
        peer_review_submission = create_submitted_peer_review_submission

        expect(peer_review_submission.workflow_state).to eq("submitted")

        assessor.destroy

        result = service.call

        expect(result).to be_nil
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("deleted")
      end
    end

    context "when submission does not exist" do
      it "returns nil" do
        peer_review_sub_assignment
        submission1 = create_submission_for(student1)
        create_assessment_request(user: student1, submission: submission1)

        result = service.call

        expect(result).to be_nil
      end
    end

    context "when submission is already unsubmitted" do
      it "returns nil" do
        peer_review_sub_assignment

        peer_review_submission = peer_review_sub_assignment.submissions.active.find_by(user_id: assessor.id)
        expect(peer_review_submission.workflow_state).to eq("unsubmitted")

        result = service.call

        expect(result).to be_nil
      end
    end

    context "when assessor has exactly the required number of peer reviews" do
      it "does not unsubmit the submission" do
        peer_review_submission = create_submitted_peer_review_submission

        expect(peer_review_submission.workflow_state).to eq("submitted")

        result = service.call

        expect(result).to be_nil
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
      end
    end

    shared_context "three completed assessments" do
      let(:student3) { user_model(name: "Student 3") }
      let(:submission1) { create_submission_for(student1) }
      let(:submission2) { create_submission_for(student2) }
      let(:submission3) { create_submission_for(student3) }

      let(:request1) do
        req = create_assessment_request(user: student1, submission: submission1)
        create_peer_review_comment_for(assessment_request: req, submission: submission1, created_at: 3.days.ago)
        req
      end

      let(:request2) do
        req = create_assessment_request(user: student2, submission: submission2)
        create_peer_review_comment_for(assessment_request: req, submission: submission2, created_at: 2.days.ago)
        req
      end

      let(:request3) do
        req = create_assessment_request(user: student3, submission: submission3)
        create_peer_review_comment_for(assessment_request: req, submission: submission3, created_at: 1.day.ago)
        req
      end

      let(:peer_review_submission) { peer_review_sub_assignment.submissions.active.find_by(user_id: assessor.id) }

      before do
        create_enrollment(course, student3, enrollment_state: "active")
        request1
        request2
        request3
      end
    end

    context "when earlier assessment is deleted but threshold still met" do
      include_context "three completed assessments"

      it "updates submitted_at to the new qualifying assessment completion time" do
        expect(peer_review_submission.workflow_state).to eq("submitted")

        peer_review_submission.update!(submitted_at: 3.days.ago)
        expect(peer_review_submission.submitted_at).to be_within(1.second).of(3.days.ago)

        request1.destroy

        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
        expect(peer_review_submission.submitted_at).to be_within(1.second).of(1.day.ago)
      end
    end

    context "when latest assessment is deleted and threshold still met" do
      include_context "three completed assessments"

      it "does not update submitted_at" do
        expect(peer_review_submission.workflow_state).to eq("submitted")

        original_submitted_at = peer_review_submission.submitted_at
        expect(original_submitted_at).to be_within(1.second).of(2.days.ago)

        request3.destroy

        result = service.call

        expect(result).to be_nil
        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("submitted")
        expect(peer_review_submission.submitted_at).to be_within(1.second).of(original_submitted_at)
      end
    end

    context "backward compatibility" do
      it "unsubmits the submission in legacy mode" do
        peer_review_submission = create_submitted_peer_review_submission
        expect(peer_review_submission.workflow_state).to eq("submitted")

        course.disable_feature!(:peer_review_allocation_and_grading)

        # Deleting assessment request triggers SubmissionUpdaterService
        request = get_assessment_request_for_assessor
        request.destroy

        peer_review_submission.reload
        expect(peer_review_submission.workflow_state).to eq("unsubmitted")
      end
    end
  end
end
