# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Mutations::CreateSubmissionComment do
  before(:once) do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment = @course.assignments.create!(title: "Example Assignment")
    @submission = @assignment.submit_homework(
      @student,
      submission_type: "online_text_entry",
      body: "body"
    )
  end

  def value_or_null(value, stringify = true)
    return "null" if value.nil?

    stringify ? "\"#{value}\"" : value
  end

  def mutation_str(submission_id: nil, attempt: nil, comment: "hello", file_ids: [], media_object_id: nil, media_object_type: nil, reviewer_submission_id: nil, group_comment: false, draft_comment: false)
    <<~GQL
      mutation {
        createSubmissionComment(input: {
          attempt: #{value_or_null(attempt, false)}
          comment: #{value_or_null(comment)}
          fileIds: #{file_ids}
          groupComment: #{group_comment}
          mediaObjectId: #{value_or_null(media_object_id)}
          mediaObjectType: #{value_or_null(media_object_type)}
          submissionId: #{value_or_null(submission_id || @submission.id)}
          reviewerSubmissionId: #{value_or_null(reviewer_submission_id)}
          draftComment: #{draft_comment}
        }) {
          submissionComment {
            _id
            attempt
            comment
            draft
            attachments {
              _id
            }
            mediaObject {
              _id
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(mutation_str(**opts), context: { current_user: })
    result.to_h.with_indifferent_access
  end

  it "creates a new submission comment" do
    result = run_mutation
    expect(
      result.dig(:data, :createSubmissionComment, :submissionComment, :_id)
    ).to eq SubmissionComment.last.id.to_s
  end

  it "creates a new submission comment and a Viewed Submission Commment for the user" do
    result = run_mutation
    expect(
      result.dig(:data, :createSubmissionComment, :submissionComment, :_id)
    ).to eq SubmissionComment.last.id.to_s
    expect(ViewedSubmissionComment.count).to eq 1
    expect(ViewedSubmissionComment.last.user).to eq @teacher
    expect(ViewedSubmissionComment.last.submission_comment_id).to eq SubmissionComment.last.id
  end

  it "requires permission to comment on the submission" do
    @student2 = @course.enroll_student(User.create!, enrollment_state: "active").user
    result = run_mutation({}, @student2)
    expect(result[:errors].length).to eq 1
    expect(result[:errors][0][:message]).to eq "not found"
  end

  describe "submission_id argument" do
    it "is gracefully handled when the submission is not found" do
      result = run_mutation(submission_id: 12_345)
      expect(result[:errors].length).to eq 1
      expect(result[:errors][0][:message]).to eq "not found"
    end
  end

  describe "comment argument" do
    it "is properly saved to the comment text" do
      result = run_mutation(comment: "dogs and cats")
      expect(
        result.dig(:data, :createSubmissionComment, :submissionComment, :comment)
      ).to eq "dogs and cats"
    end

    context "draft comment" do
      it "is saved as a draft comment" do
        result = run_mutation(draft_comment: true)
        expect(
          result.dig(:data, :createSubmissionComment, :submissionComment, :draft)
        ).to be true
      end

      it "is not saved as a draft comment" do
        result = run_mutation(draft_comment: false)
        expect(
          result.dig(:data, :createSubmissionComment, :submissionComment, :draft)
        ).to be false
      end
    end
  end

  describe "attempt argument" do
    it "is 0 if unused" do
      expect(
        run_mutation.dig(:data, :createSubmissionComment, :submissionComment, :attempt)
      ).to eq 0
    end

    it "can be used to set the submission comment attempt" do
      @submission.update!(attempt: 3)
      result = run_mutation(attempt: 2)
      expect(
        result.dig(:data, :createSubmissionComment, :submissionComment, :attempt)
      ).to eq 2
    end

    it "is gracefully handled when invalid" do
      @submission.update!(attempt: 3)
      result = run_mutation(attempt: 4)
      errors = result.dig(:data, :createSubmissionComment, :errors)
      expect(errors.length).to eq 1
      expect(errors[0][:attribute]).to eq "attempt"
      expect(errors[0][:message]).to eq "attempt must not be larger than number of submission attempts"
      expect(result.dig(:data, :createSubmissionComment, :submissionComment)).to be_nil
    end
  end

  describe "file_ids argument" do
    before(:once) do
      opts = { user: @teacher, context: @assignment }
      @attachment1 = create_attachment_for_file_upload_submission!(@submission, opts)
      @attachment2 = create_attachment_for_file_upload_submission!(@submission, opts)
    end

    it "lets you attach files to this submission comment" do
      result = run_mutation(file_ids: [@attachment1.id.to_s])
      attachments = result.dig(:data, :createSubmissionComment, :submissionComment, :attachments)
      expect(attachments.length).to eq 1
      expect(attachments[0][:_id]).to eq @attachment1.id.to_s
    end

    it "can attach more then one file" do
      result = run_mutation(file_ids: [@attachment1.id.to_s, @attachment2.id.to_s])
      attachments = result.dig(:data, :createSubmissionComment, :submissionComment, :attachments)
      expect(attachments.length).to eq 2
      expect(attachments[0][:_id]).to eq @attachment1.id.to_s
      expect(attachments[1][:_id]).to eq @attachment2.id.to_s
    end

    it "requires permissions for all files" do
      opts = { user: @student, context: @assignment }
      student_attachment = create_attachment_for_file_upload_submission!(@submission, opts)
      result = run_mutation({ file_ids: [@attachment1.id.to_s, student_attachment.id.to_s] })
      expect(result[:errors].length).to eq 1
      expect(result[:errors][0][:message]).to eq "not found"
    end

    it "gracefully handles an attachment not being found" do
      result = run_mutation(file_ids: ["12345"])
      expect(result[:errors].length).to eq 1
      expect(result[:errors][0][:message]).to eq "not found"
    end
  end

  describe "media objects" do
    before(:once) do
      @media_object = media_object
    end

    it "lets you attach a media comment to the submission comment" do
      result = run_mutation(media_object_id: @media_object.media_id)
      expect(
        result.dig(:data, :createSubmissionComment, :submissionComment, :mediaObject, :_id)
      ).to eq @media_object.media_id
    end

    it "saves the media comment type on the created submission comment object" do
      run_mutation(media_object_id: @media_object.media_id, media_object_type: "video")
      comment = SubmissionComment.find_by(media_comment_id: @media_object.media_id)
      expect(comment.media_comment_type).to eq "video"
    end

    it "gracefully handles the media object not being found" do
      result = run_mutation(media_object_id: "m-2pRR7YQkQAR9mBzBdwmT1EZbYfUpzkMY")
      expect(result[:errors].length).to eq 1
      expect(result[:errors][0][:message]).to eq "not found"
    end
  end

  describe "reviewer_submission_id argument" do
    before(:once) do
      @assignment.update_attribute(:peer_reviews, true)
      reviewer = User.create!(name: "John Connor")
      @course.enroll_user(reviewer, "StudentEnrollment", enrollment_state: "active")
      @assessment_request = @assignment.assign_peer_review(reviewer, @student)
      @reviewer_submission = @assignment.submission_for_student(reviewer)
    end

    it "marks the workflow_state as complete for the associated assessment request" do
      expect(@assessment_request.workflow_state).to eq "assigned"
      run_mutation(reviewer_submission_id: @reviewer_submission.id)
      @assessment_request.reload
      expect(@assessment_request.workflow_state).to eq "completed"
    end

    it "gracefully handles the reviewer submission not being found" do
      result = run_mutation(reviewer_submission_id: "9")
      expect(result[:errors].length).to eq 1
      expect(result[:errors][0][:message]).to eq "not found"
    end

    it "gracefully handles the assessment request not being found" do
      @assessment_request.destroy!
      result = run_mutation(reviewer_submission_id: @reviewer_submission.id)
      expect(result[:errors].length).to eq 1
      expect(result[:errors][0][:message]).to eq "not found"
    end
  end

  context "group assignments" do
    before(:once) do
      @first_student = @student
      @second_student = @course.enroll_student(User.create!, enrollment_state: "active").user
      group_category = @course.group_categories.create!(name: "My Category")
      @group = @course.groups.create!(name: "Group A", group_category:)
      @group.add_user(@student)
      @group.add_user(@second_student)
      @assignment = @course.assignments.create!(
        title: "Group Assignment",
        submission_types: "online_text_entry",
        grade_group_students_individually: false,
        group_category:
      )
    end

    let(:first_student_submission) { @assignment.submissions.find_by(user: @first_student) }
    let(:second_student_submission) { @assignment.submissions.find_by(user: @second_student) }

    describe "group_comment argument" do
      it "is ignored for group assignments grading students as a group (all comments to go to the whole group)" do
        run_mutation(submission_id: first_student_submission.id, comment: "ohai", group_comment: false)
        aggregate_failures do
          expect(first_student_submission.submission_comments.where(comment: "ohai").count).to eq 1
          expect(second_student_submission.submission_comments.where(comment: "ohai").count).to eq 1
        end
      end

      it "is ignored for non-group assignments (all comments go to the individual only)" do
        @assignment.update!(group_category: nil)
        run_mutation(submission_id: first_student_submission.id, comment: "ohai", group_comment: true)
        aggregate_failures do
          expect(first_student_submission.submission_comments.where(comment: "ohai").count).to eq 1
          expect(second_student_submission.submission_comments.where(comment: "ohai")).to be_empty
        end
      end

      it "sends the comment to the group if group_comment is true, for group assignments grading students individually" do
        @assignment.update!(grade_group_students_individually: true)
        run_mutation(submission_id: first_student_submission.id, comment: "ohai", group_comment: true)
        aggregate_failures do
          expect(first_student_submission.submission_comments.where(comment: "ohai").count).to eq 1
          expect(second_student_submission.submission_comments.where(comment: "ohai").count).to eq 1
        end
      end

      it "sends the comment to the individual only if group_comment is false, for group assignments grading students individually" do
        @assignment.update!(grade_group_students_individually: true)
        run_mutation(submission_id: first_student_submission.id, comment: "ohai", group_comment: false)
        aggregate_failures do
          expect(first_student_submission.submission_comments.where(comment: "ohai").count).to eq 1
          expect(second_student_submission.submission_comments.where(comment: "ohai")).to be_empty
        end
      end
    end
  end
end
