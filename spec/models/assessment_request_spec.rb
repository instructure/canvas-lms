# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe AssessmentRequest do
  before :once do
    course_with_teacher(active_all: true)
    @submission_student = student_in_course(active_all: true, course: @course).user
    @review_student = student_in_course(active_all: true, course: @course).user
    @assignment = @course.assignments.create!
    submission = @assignment.find_or_create_submission(@user)
    assessor_submission = @assignment.find_or_create_submission(@review_student)
    @request = AssessmentRequest.create!(
      user: @submission_student, asset: submission, assessor_asset: assessor_submission, assessor: @review_student
    )
    communication_channel(@student, { username: "test@example.com", active_cc: true })
  end

  def create_assessment_request(workflow_state: "assigned")
    AssessmentRequest.create!(
      user: @submission_student,
      asset: @assignment.find_or_create_submission(@submission_student),
      assessor_asset: @assignment.find_or_create_submission(@review_student),
      assessor: @review_student,
      workflow_state:
    )
  end

  describe "workflow" do
    it "defaults to assigned" do
      expect(@request).to be_assigned
    end

    it "can be completed" do
      @request.complete!
      expect(@request).to be_completed
    end
  end

  describe "peer review invitation" do
    before :once do
      @notification_name = "Peer Review Invitation"
      notification = Notification.create!(name: @notification_name, category: "Invitation")
      NotificationPolicy.create!(
        notification:,
        communication_channel: @student.communication_channel,
        frequency: "immediately"
      )
    end

    it "sends a notification if the course and assignment are published" do
      @request.send_reminder!

      expect(@request.messages_sent.keys).to include(@notification_name)
    end

    it "does not send a notification if the course is unpublished" do
      @course.update!(workflow_state: "created")
      @request.reload
      @request.send_reminder!

      expect(@request.messages_sent.keys).to be_empty
    end

    it "does not send a notification if the assignment is unpublished" do
      @assignment.update!(workflow_state: "unpublished")
      @request.reload
      @request.send_reminder!

      expect(@request.messages_sent.keys).to be_empty
    end
  end

  describe "rubric assessment reminder" do
    before :once do
      @notification_name = "Rubric Assessment Submission Reminder"
      notification = Notification.create!(name: @notification_name, category: "Invitation")
      NotificationPolicy.create!(
        notification:,
        communication_channel: @student.communication_channel,
        frequency: "immediately"
      )
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      @assignment.update_attribute(:title, "new assmt title")
      @request.rubric_association = @association
      @request.save!
    end

    it "sends a notification if the course and assignment are published" do
      @request.send_reminder!

      expect(@request.messages_sent.keys).to include(@notification_name)
      expect(@request.messages_sent[@notification_name].count).to eq 1
      message = @request.messages_sent[@notification_name].first
      expect(message.body).to include(@assignment.title)
    end

    it "does not send a notification if the course is unpublished" do
      @course.update!(workflow_state: "created")
      @request.reload
      @request.send_reminder!

      expect(@request.messages_sent.keys).to be_empty
    end

    it "does not send a notification if the assignment is unpublished" do
      @assignment.update!(workflow_state: "unpublished")
      @request.reload
      @request.send_reminder!

      expect(@request.messages_sent.keys).to be_empty
    end

    it "sends the correct url if anonymous" do
      @assignment.update(anonymous_peer_reviews: true)
      @request.reload
      @request.send_reminder!

      expect(@request.messages_sent.keys).to include(@notification_name)
      message = @request.messages_sent[@notification_name].first
      expect(message.body).to include(
        "/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{@request.asset.anonymous_id}"
      )
    end
  end

  describe "policies" do
    before :once do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      @assignment.update_attribute(:anonymous_peer_reviews, true)
      @reviewed = @student
      @reviewer = student_in_course(active_all: true, course: @course).user
      @assessment_request = @assignment.assign_peer_review(@reviewer, @reviewed)
      @assessment_request.rubric_association = @association
      @assessment_request.save!
    end

    it "prevents reviewer from seeing reviewed name" do
      expect(@assessment_request).not_to be_grants_right(@reviewer, :read_assessment_user)
    end

    it "allows reviewed to see own name" do
      expect(@assessment_request).to be_grants_right(@reviewed, :read_assessment_user)
    end

    it "allows teacher to see reviewed users name" do
      expect(@assessment_request).to be_grants_right(@teacher, :read_assessment_user)
    end
  end

  describe "#delete_ignores" do
    before :once do
      @ignore = Ignore.create!(asset: @request, user: @student, purpose: "reviewing")
    end

    it "deletes ignores if the request is completed" do
      @request.complete!
      expect { @ignore.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "deletes ignores if the request is deleted" do
      @request.destroy!
      expect { @ignore.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it "does not delete ignores if the request is updated, but not completed or deleted" do
      @request.assessor = @teacher
      @request.save!
      expect(@ignore.reload).to eq @ignore
    end
  end

  describe "#active_rubric_association?" do
    before(:once) do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      @request.rubric_association = @association
      @request.save!
    end

    it "returns false if there is no rubric association" do
      @request.update!(rubric_association: nil)
      expect(@request).not_to be_active_rubric_association
    end

    it "returns false if the rubric association is soft-deleted" do
      @association.destroy
      expect(@request).not_to be_active_rubric_association
    end

    it "returns true if the rubric association exists and is active" do
      expect(@request).to be_active_rubric_association
    end
  end

  describe "#available?" do
    before :once do
      @assignment.update!(peer_reviews: true, submission_types: "online_text_entry")
    end

    it "available should be true when both user and assessor have submitted homework" do
      assessment_request = AssessmentRequest.create!(
        asset: @assignment.submit_homework(@submission_student, body: "hi"),
        user: @submission_student,
        assessor: @review_student,
        assessor_asset: @assignment.submit_homework(@review_student, body: "hi")
      )
      expect(assessment_request).to be_available
    end

    it "available should be false when only user has submitted homework" do
      assessment_request = AssessmentRequest.create!(
        asset: @assignment.submit_homework(@submission_student, body: "hi"),
        user: @submission_student,
        assessor: @review_student,
        assessor_asset: @assignment.submission_for_student(@review_student)
      )
      expect(assessment_request).not_to be_available
    end

    it "available should be false when only accessor has submitted homework" do
      assessment_request = AssessmentRequest.create!(
        asset: @assignment.submission_for_student(@submission_student),
        user: @submission_student,
        assessor: @review_student,
        assessor_asset: @assignment.submit_homework(@review_student, body: "hi")
      )
      expect(assessment_request).not_to be_available
    end

    it "available should be true when the submission type of the assignment contains 'none'" do
      @assignment.update(submission_types: "none")
      assessment_request = AssessmentRequest.create!(
        asset: @assignment.submission_for_student(@submission_student),
        user: @submission_student,
        assessor: @review_student,
        assessor_asset: @assignment.submission_for_student(@review_student)
      )
      expect(assessment_request).to be_available
    end

    it "available should be true when the submission type of the assignment contains 'on paper'" do
      @assignment.update(submission_types: "on_paper")
      assessment_request = AssessmentRequest.create!(
        asset: @assignment.submission_for_student(@submission_student),
        user: @submission_student,
        assessor: @review_student,
        assessor_asset: @assignment.submission_for_student(@review_student)
      )
      expect(assessment_request).to be_available
    end

    context "with peer_review_allocation_and_grading feature flag" do
      before :once do
        @course.enable_feature!(:peer_review_allocation_and_grading)
      end

      context "when peer_review_submission_required is true" do
        before :once do
          @assignment.update!(peer_review_submission_required: true)
        end

        it "is available when both assessee and assessor have submitted" do
          assessment_request = AssessmentRequest.create!(
            asset: @assignment.submit_homework(@submission_student, body: "hi"),
            user: @submission_student,
            assessor: @review_student,
            assessor_asset: @assignment.submit_homework(@review_student, body: "hi")
          )
          expect(assessment_request).to be_available
        end

        it "is not available when only assessee has submitted" do
          assessment_request = AssessmentRequest.create!(
            asset: @assignment.submit_homework(@submission_student, body: "hi"),
            user: @submission_student,
            assessor: @review_student,
            assessor_asset: @assignment.submission_for_student(@review_student)
          )
          expect(assessment_request).not_to be_available
        end

        it "is not available when only assessor has submitted" do
          assessment_request = AssessmentRequest.create!(
            asset: @assignment.submission_for_student(@submission_student),
            user: @submission_student,
            assessor: @review_student,
            assessor_asset: @assignment.submit_homework(@review_student, body: "hi")
          )
          expect(assessment_request).not_to be_available
        end
      end

      context "when peer_review_submission_required is false" do
        before :once do
          @assignment.update!(peer_review_submission_required: false)
        end

        it "is available when both assessee and assessor have submitted" do
          assessment_request = AssessmentRequest.create!(
            asset: @assignment.submit_homework(@submission_student, body: "hi"),
            user: @submission_student,
            assessor: @review_student,
            assessor_asset: @assignment.submit_homework(@review_student, body: "hi")
          )
          expect(assessment_request).to be_available
        end

        it "is available when only assessee has submitted" do
          assessment_request = AssessmentRequest.create!(
            asset: @assignment.submit_homework(@submission_student, body: "hi"),
            user: @submission_student,
            assessor: @review_student,
            assessor_asset: @assignment.submission_for_student(@review_student)
          )
          expect(assessment_request).to be_available
        end

        it "is not available when only assessor has submitted" do
          assessment_request = AssessmentRequest.create!(
            asset: @assignment.submission_for_student(@submission_student),
            user: @submission_student,
            assessor: @review_student,
            assessor_asset: @assignment.submit_homework(@review_student, body: "hi")
          )
          expect(assessment_request).not_to be_available
        end
      end
    end
  end

  describe "#for_active_users" do
    it "excludes users that aren't active" do
      course = @assignment.course
      course.enrollments.find_by(user: @submission_student).destroy
      user_ids = AssessmentRequest.for_active_users(course).pluck(:user_id)

      expect(user_ids).not_to include @submission_student.id
    end

    it "includes users that are active" do
      course = @assignment.course
      user_ids = AssessmentRequest.for_active_users(course).pluck(:user_id)

      expect(user_ids).to include @submission_student.id
    end
  end

  describe "peer_review_sub_assignment association" do
    let(:peer_review_sub_assignment) do
      PeerReviewSubAssignment.create!(
        title: "Peer Review Sub Assignment",
        context: @course,
        parent_assignment: @assignment
      )
    end

    def assign_peer_review_sub_assignment
      @request.peer_review_sub_assignment = peer_review_sub_assignment
      @request.save!
    end

    it "can be created without a peer_review_sub_assignment" do
      expect(@request.peer_review_sub_assignment).to be_nil
      expect(@request).to be_valid
    end

    it "can be associated with a peer_review_sub_assignment" do
      assign_peer_review_sub_assignment

      expect(@request.peer_review_sub_assignment).to eq(peer_review_sub_assignment)
      expect(@request.peer_review_sub_assignment_id).to eq(peer_review_sub_assignment.id)
    end

    it "allows peer_review_sub_assignment to be nil" do
      assign_peer_review_sub_assignment

      @request.peer_review_sub_assignment = nil
      @request.save!

      expect(@request.peer_review_sub_assignment).to be_nil
      expect(@request.peer_review_sub_assignment_id).to be_nil
    end

    it "does not delete the peer_review_sub_assignment when assessment_request is deleted" do
      assign_peer_review_sub_assignment

      @request.destroy

      expect { peer_review_sub_assignment.reload }.not_to raise_error
    end

    it "can query assessment_requests by peer_review_sub_assignment" do
      assign_peer_review_sub_assignment

      other_request = AssessmentRequest.create!(
        user: @submission_student,
        asset: @assignment.find_or_create_submission(@submission_student),
        assessor_asset: @assignment.find_or_create_submission(@review_student),
        assessor: @review_student
      )

      requests_with_sub_assignment = AssessmentRequest.where(peer_review_sub_assignment:)
      requests_without_sub_assignment = AssessmentRequest.where(peer_review_sub_assignment: nil)

      expect(requests_with_sub_assignment).to include(@request)
      expect(requests_with_sub_assignment).not_to include(other_request)
      expect(requests_without_sub_assignment).to include(other_request)
      expect(requests_without_sub_assignment).not_to include(@request)
    end
  end

  describe "#create_peer_review_submission" do
    let(:service_double) { instance_double(PeerReview::SubmissionCreatorService) }

    before :once do
      @assignment.update!(peer_reviews: true)
      @assignment.context.enable_feature!(:peer_review_allocation_and_grading)
      peer_review_sub_assignment = PeerReviewSubAssignment.create!(parent_assignment: @assignment)
      @request.peer_review_sub_assignment = peer_review_sub_assignment
      @request.save!
    end

    it "calls SubmissionCreatorService when workflow state changes from assigned to completed and peer_review_sub_assignment exists" do
      expect(PeerReview::SubmissionCreatorService).to receive(:new)
        .with(parent_assignment: @assignment, assessor: @review_student)
        .and_return(service_double)
      expect(service_double).to receive(:call)

      @request.complete!
    end

    it "does not call service when workflow state does not change" do
      @request.update!(workflow_state: "completed")

      expect(PeerReview::SubmissionCreatorService).not_to receive(:new)

      @request.save!
    end

    it "does not call service when workflow state changes but not from assigned to completed" do
      completed_request = create_assessment_request(workflow_state: "completed")

      expect(PeerReview::SubmissionCreatorService).not_to receive(:new)

      completed_request.update!(workflow_state: "assigned")
    end

    it "does not call service when peer_review_sub_assignment is nil" do
      @request.peer_review_sub_assignment = nil
      @request.save!
      expect(@request.peer_review_sub_assignment).to be_nil
      expect(PeerReview::SubmissionCreatorService).not_to receive(:new)

      @request.complete!
    end

    context "with feature flag disabled but peer_review_sub_assignment present" do
      it "calls SubmissionCreatorService even when feature flag is disabled" do
        @assignment.context.disable_feature!(:peer_review_allocation_and_grading)
        service_double = instance_double(PeerReview::SubmissionCreatorService)

        expect(PeerReview::SubmissionCreatorService).to receive(:new)
          .with(parent_assignment: @assignment, assessor: @review_student)
          .and_return(service_double)
        expect(service_double).to receive(:call)

        @request.complete!
      end
    end
  end

  describe "#update_peer_review_submission" do
    before :once do
      @course.enable_feature!(:peer_review_allocation_and_grading)
      @assignment.update!(peer_reviews: true, peer_review_count: 2)

      @peer_review_sub = peer_review_model(parent_assignment: @assignment)
      @assignment.reload

      @reviewer1 = student_in_course(active_all: true, course: @course).user
      @reviewee1 = student_in_course(active_all: true, course: @course).user
      @reviewee2 = student_in_course(active_all: true, course: @course).user
    end

    def create_completed_review(reviewer, reviewee)
      submission = @assignment.submit_homework(reviewee, submission_type: "online_text_entry", body: "test")
      request = @assignment.assign_peer_review(reviewer, reviewee)
      request.update!(workflow_state: "completed", peer_review_sub_assignment_id: @peer_review_sub.id)
      SubmissionComment.create!(
        submission:,
        author: reviewer,
        comment: "peer review feedback",
        assessment_request: request,
        workflow_state: "published"
      )
      request
    end

    def create_submitted_peer_review_submission(reviewer)
      @peer_review_sub.submit_homework(
        reviewer,
        submission_type: PeerReviewSubAssignment::PEER_REVIEW_SUBMISSION_TYPE,
        submitted_at: Time.zone.now
      )
    end

    context "with peer review submission comments" do
      it "unsubmits peer review submission when completed peer reviews fall below threshold" do
        request1 = create_completed_review(@reviewer1, @reviewee1)
        create_completed_review(@reviewer1, @reviewee2)
        submission = create_submitted_peer_review_submission(@reviewer1)

        expect(submission).to be_present
        expect(submission.workflow_state).to eq("submitted")

        request1.destroy

        submission.reload
        expect(submission.workflow_state).to eq("unsubmitted")
      end

      it "does not unsubmit when peer reviews still meet threshold" do
        reviewee3 = student_in_course(active_all: true, course: @course).user
        request1 = create_completed_review(@reviewer1, @reviewee1)
        create_completed_review(@reviewer1, @reviewee2)
        create_completed_review(@reviewer1, reviewee3)
        submission = create_submitted_peer_review_submission(@reviewer1)

        expect(submission.workflow_state).to eq("submitted")

        request1.destroy

        submission.reload
        expect(submission.workflow_state).to eq("submitted")
      end

      it "does not unsubmit if assessment request was not completed" do
        create_completed_review(@reviewer1, @reviewee1)
        create_completed_review(@reviewer1, @reviewee2)
        submission = create_submitted_peer_review_submission(@reviewer1)

        expect(submission.workflow_state).to eq("submitted")

        request3 = @assignment.assign_peer_review(@reviewer1, student_in_course(active_all: true, course: @course).user)

        request3.destroy

        submission.reload
        expect(submission.workflow_state).to eq("submitted")
      end

      context "with feature flag disabled" do
        it "still unsubmits in legacy mode" do
          request1 = create_completed_review(@reviewer1, @reviewee1)
          create_completed_review(@reviewer1, @reviewee2)
          submission = create_submitted_peer_review_submission(@reviewer1)

          expect(submission.workflow_state).to eq("submitted")

          @course.disable_feature!(:peer_review_allocation_and_grading)

          request1.destroy

          submission.reload
          expect(submission.workflow_state).to eq("unsubmitted")
        end
      end
    end

    context "with peer review rubric assessments" do
      before :once do
        rubric_model
        @rubric_association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        @assignment.reload
      end

      def create_completed_review_with_rubric(reviewer, reviewee)
        submission = @assignment.submit_homework(reviewee, submission_type: "online_text_entry", body: "test")
        request = @assignment.assign_peer_review(reviewer, reviewee)
        request.update!(workflow_state: "completed", peer_review_sub_assignment_id: @peer_review_sub.id)

        rubric_assessment = RubricAssessment.create!(
          rubric: @rubric,
          artifact: submission,
          assessment_type: "peer_review",
          assessor: reviewer,
          user: reviewee,
          rubric_association: @rubric_association,
          data: @rubric.criteria.map do |criterion|
            {
              criterion_id: criterion[:id],
              points: criterion[:points],
              comments: "Good work"
            }
          end
        )

        request.update!(rubric_assessment:)
        request
      end

      it "unsubmits peer review submission when completed rubric-based peer reviews fall below threshold" do
        request1 = create_completed_review_with_rubric(@reviewer1, @reviewee1)
        create_completed_review_with_rubric(@reviewer1, @reviewee2)
        submission = create_submitted_peer_review_submission(@reviewer1)

        expect(submission).to be_present
        expect(submission.workflow_state).to eq("submitted")

        request1.destroy

        submission.reload
        expect(submission.workflow_state).to eq("unsubmitted")
      end

      it "does not unsubmit when rubric-based peer reviews still meet threshold" do
        reviewee3 = student_in_course(active_all: true, course: @course).user
        request1 = create_completed_review_with_rubric(@reviewer1, @reviewee1)
        create_completed_review_with_rubric(@reviewer1, @reviewee2)
        create_completed_review_with_rubric(@reviewer1, reviewee3)
        submission = create_submitted_peer_review_submission(@reviewer1)

        expect(submission.workflow_state).to eq("submitted")

        request1.destroy

        submission.reload
        expect(submission.workflow_state).to eq("submitted")
      end

      it "does not unsubmit if rubric assessment request was not completed" do
        create_completed_review_with_rubric(@reviewer1, @reviewee1)
        create_completed_review_with_rubric(@reviewer1, @reviewee2)
        submission = create_submitted_peer_review_submission(@reviewer1)

        expect(submission.workflow_state).to eq("submitted")

        request3 = @assignment.assign_peer_review(@reviewer1, student_in_course(active_all: true, course: @course).user)

        request3.destroy

        submission.reload
        expect(submission.workflow_state).to eq("submitted")
      end

      context "with feature flag disabled" do
        it "still unsubmits with rubric assessments in legacy mode" do
          request1 = create_completed_review_with_rubric(@reviewer1, @reviewee1)
          create_completed_review_with_rubric(@reviewer1, @reviewee2)
          submission = create_submitted_peer_review_submission(@reviewer1)

          expect(submission.workflow_state).to eq("submitted")

          @course.disable_feature!(:peer_review_allocation_and_grading)

          request1.destroy

          submission.reload
          expect(submission.workflow_state).to eq("unsubmitted")
        end
      end
    end
  end

  describe "#assessment_request_was_completed?" do
    it "returns true when workflow state changes from assigned to completed" do
      @request.complete!

      expect(@request.assessment_request_was_completed?).to be true
    end

    it "returns false when workflow state changes but not from assigned to completed" do
      completed_request = create_assessment_request(workflow_state: "completed")

      completed_request.workflow_state = "assigned"
      completed_request.save!

      expect(completed_request.assessment_request_was_completed?).to be false
    end

    it "returns false when workflow state does not change" do
      @request.save!

      expect(@request.assessment_request_was_completed?).to be false
    end

    it "returns false for a new record being created as completed" do
      request = create_assessment_request(workflow_state: "completed")

      expect(request.assessment_request_was_completed?).to be false
    end
  end

  describe "linking to peer_review_sub_assignment on creation" do
    before :once do
      @assignment.update!(peer_reviews: true)
    end

    let(:reviewer) { student_in_course(active_all: true, course: @course).user }
    let(:reviewee) { student_in_course(active_all: true, course: @course).user }

    context "when all conditions are met" do
      before :once do
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          title: "Test Peer Review",
          context: @course,
          parent_assignment: @assignment
        )
      end

      it "links assessment request to peer_review_sub_assignment when created via assign_peer_review" do
        assessment_request = @assignment.assign_peer_review(reviewer, reviewee)

        expect(assessment_request.peer_review_sub_assignment_id).to eq(@peer_review_sub_assignment.id)
        expect(assessment_request.peer_review_sub_assignment).to eq(@peer_review_sub_assignment)
      end

      it "sets peer_review_sub_assignment_id during creation process" do
        assessment_request = @assignment.assign_peer_review(reviewer, reviewee)

        expect(assessment_request).to be_persisted
        expect(assessment_request.peer_review_sub_assignment_id).to eq(@peer_review_sub_assignment.id)
      end
    end

    context "when peer_review_allocation_and_grading feature flag is disabled" do
      before :once do
        @peer_review_sub_assignment = peer_review_model(parent_assignment: @assignment)
        @course.disable_feature!(:peer_review_allocation_and_grading)
      end

      it "links assessment request to peer_review_sub_assignment even when feature flag is disabled" do
        assessment_request = @assignment.assign_peer_review(reviewer, reviewee)

        expect(assessment_request.peer_review_sub_assignment_id).to eq(@peer_review_sub_assignment.id)
        expect(assessment_request.peer_review_sub_assignment).to eq(@peer_review_sub_assignment)
      end
    end

    context "legacy mode backward compatibility" do
      it "maintains peer_review_sub_assignment linkage when feature flag is toggled off" do
        @assignment.update!(peer_reviews: true)

        peer_review_sub = peer_review_model(parent_assignment: @assignment)

        first_request = @assignment.assign_peer_review(reviewer, reviewee)
        expect(first_request.peer_review_sub_assignment_id).to eq(peer_review_sub.id)

        @course.disable_feature!(:peer_review_allocation_and_grading)

        new_reviewer = student_in_course(active_all: true, course: @course).user
        second_request = @assignment.assign_peer_review(new_reviewer, reviewee)

        expect(second_request.peer_review_sub_assignment_id).to eq(peer_review_sub.id)
        expect(second_request.peer_review_sub_assignment).to eq(peer_review_sub)
      end
    end

    context "when parent assignment does not have peer_reviews enabled" do
      before :once do
        @assignment.update!(peer_reviews: false)
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @peer_review_sub_assignment = PeerReviewSubAssignment.create!(
          title: "Test Peer Review",
          context: @course,
          parent_assignment: @assignment
        )
      end

      it "does not link assessment request when peer_reviews is false" do
        assessment_request = @assignment.assign_peer_review(reviewer, reviewee)

        expect(assessment_request.peer_review_sub_assignment_id).to be_nil
      end
    end

    context "when peer_review_sub_assignment does not exist" do
      before :once do
        @course.enable_feature!(:peer_review_allocation_and_grading)
      end

      it "creates assessment request without linking when sub-assignment does not exist" do
        assessment_request = @assignment.assign_peer_review(reviewer, reviewee)

        expect(assessment_request).to be_persisted
        expect(assessment_request.peer_review_sub_assignment_id).to be_nil
      end

      it "does not raise an error when sub-assignment does not exist" do
        expect { @assignment.assign_peer_review(reviewer, reviewee) }.not_to raise_error
      end
    end

    context "when an existing assessment request exists" do
      before :once do
        @course.enable_feature!(:peer_review_allocation_and_grading)
        @existing_request = @assignment.assign_peer_review(reviewer, reviewee)
      end

      it "does not retroactively link existing requests when sub-assignment is created later" do
        expect(@existing_request.peer_review_sub_assignment_id).to be_nil

        PeerReviewSubAssignment.create!(
          title: "Test Peer Review",
          context: @course,
          parent_assignment: @assignment
        )

        @existing_request.reload
        expect(@existing_request.peer_review_sub_assignment_id).to be_nil
      end
    end

    context "consistency with PeerReviewCreatorService" do
      it "produces the same linking behavior as PeerReviewCreatorService for new requests" do
        # There seems to be some weird issue with feature_flags_cache
        # (triggered by something as simple as an `account.account_domains`) if
        # we enable the flag directly on @course
        @assignment.context.enable_feature!(:peer_review_allocation_and_grading)

        assessment_request = @assignment.assign_peer_review(reviewer, reviewee)
        expect(assessment_request.peer_review_sub_assignment_id).to be_nil

        service = PeerReview::PeerReviewCreatorService.new(parent_assignment: @assignment)
        peer_review_sub = service.call

        assessment_request.reload
        expect(assessment_request.peer_review_sub_assignment_id).to eq(peer_review_sub.id)

        new_reviewer = student_in_course(active_all: true, course: @course).user
        new_assessment_request = @assignment.assign_peer_review(new_reviewer, reviewee)

        expect(new_assessment_request.peer_review_sub_assignment_id).to eq(peer_review_sub.id)
      end
    end
  end

  describe ".completed_for_assignment" do
    it "returns completed assessment requests for a given assignment" do
      completed_request = create_assessment_request(workflow_state: "completed")
      _incomplete_request = create_assessment_request(workflow_state: "assigned")

      results = AssessmentRequest.completed_for_assignment(@assignment.id)

      expect(results).to include(completed_request)
      expect(results.count).to eq(1)
    end

    it "does not return assessment requests from other assignments" do
      other_assignment = @course.assignments.create!
      _other_request = AssessmentRequest.create!(
        user: @submission_student,
        asset: other_assignment.find_or_create_submission(@submission_student),
        assessor_asset: other_assignment.find_or_create_submission(@review_student),
        assessor: @review_student,
        workflow_state: "completed"
      )

      results = AssessmentRequest.completed_for_assignment(@assignment.id)

      expect(results.count).to eq(0)
    end
  end
end
