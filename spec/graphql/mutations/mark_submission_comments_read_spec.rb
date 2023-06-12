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

describe Mutations::MarkSubmissionCommentsRead do
  before(:once) do
    @account = Account.create!
    @course = @account.courses.create!
    @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    @student = @course.enroll_student(User.create!, enrollment_state: "active").user
    @student2 = @course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment = @course.assignments.create!(title: "Example Assignment")
    @submission = @assignment.submit_homework(
      @student,
      submission_type: "online_text_entry",
      body: "body"
    )
    @student_comment = @submission.submission_comments.create!(author: @student, comment: "whats up")
    @teacher_comment = @submission.submission_comments.create!(author: @teacher, comment: "teachers whats up")
  end

  def mutation_str(submission_id: nil, submission_comment_ids: [])
    <<~GQL
      mutation {
        markSubmissionCommentsRead(input: {
          submissionCommentIds: #{submission_comment_ids}
          submissionId: #{submission_id || @submission.id}
        }) {
          submissionComments {
            _id
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

  it "marks submission as read" do
    result = run_mutation(submission_comment_ids: @student_comment.id.to_s)
    expect(
      result.dig(:data, :markSubmissionCommentsRead, :submissionComments).count
    ).to eq 1
    expect(
      result.dig(:data, :markSubmissionCommentsRead, :submissionComments)[0][:_id].to_i
    ).to eq @student_comment.id
    expect(ViewedSubmissionComment.count).to eq 1
    expect(ViewedSubmissionComment.last.user).to eq @teacher
    expect(ViewedSubmissionComment.last.submission_comment_id).to eq @student_comment.id
    expect(@student_comment.read?(@teacher)).to be true
  end

  it "requires permission to mark submission as read" do
    result = run_mutation({ submission_comment_ids: @student_comment.id.to_s }, @student2)
    expect(
      result.dig(:data, :markSubmissionCommentsRead, :submissionComments)
    ).to be_nil
  end

  it "will mark multiple submission comments as read" do
    @student_comment = @submission.submission_comments.create!(author: @student, comment: "whats up")
    student_comment2 = @submission.submission_comments.create!(author: @student, comment: "whats up")
    result = run_mutation(submission_comment_ids: [@student_comment.id.to_s, student_comment2.id.to_s])
    expect(
      result.dig(:data, :markSubmissionCommentsRead, :submissionComments).count
    ).to eq 2
    expect(
      result.dig(:data, :markSubmissionCommentsRead, :submissionComments).pluck(:_id)
    ).to eq [@student_comment.id.to_s, student_comment2.id.to_s]
    expect(ViewedSubmissionComment.count).to eq 2
    expect(@student_comment.read?(@teacher)).to be true
    expect(student_comment2.read?(@teacher)).to be true
  end

  describe "observer context" do
    it "will mark a comment as read for observers" do
      observer = @course.enroll_user(User.create!, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id).user
      result = run_mutation({ submission_comment_ids: [@teacher_comment.id.to_s] }, observer)

      expect(
        result.dig(:data, :markSubmissionCommentsRead, :submissionComments).count
      ).to eq 1
      expect(
        result.dig(:data, :markSubmissionCommentsRead, :submissionComments)[0][:_id].to_i
      ).to eq @teacher_comment.id
      expect(ViewedSubmissionComment.count).to eq 1
      expect(ViewedSubmissionComment.last.user).to eq observer
      expect(ViewedSubmissionComment.last.submission_comment_id).to eq @teacher_comment.id
      expect(@teacher_comment.read?(observer)).to be true
    end
  end
end
