# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

RSpec.describe Mutations::PostDraftSubmissionComment do
  def mutation_str(submission_comment_id: nil)
    <<~GQL
      mutation MyMutation {
        postDraftSubmissionComment(input: {submissionCommentId: "#{submission_comment_id}"}) {
          submissionComment {
            _id
            comment
            draft
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @course.account.root_account,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

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
    @student_comment = @submission.submission_comments.create!(author: @student, comment: "whats up")
    @student_draft_comment = @submission.submission_comments.create(author: @student, comment: "student draft", draft: true)
    @teacher_comment = @submission.submission_comments.create!(author: @teacher, comment: "teachers whats up")
    @teacher_draft_comment = @submission.submission_comments.create(author: @teacher, comment: "teachers draft", draft: true)
  end

  it "updates a draft comment" do
    result = run_mutation(submission_comment_id: @teacher_draft_comment.id)
    expect(result.dig("data", "postDraftSubmissionComment", "submissionComment", "comment")).to eq "teachers draft"
    expect(result.dig("data", "postDraftSubmissionComment", "submissionComment", "draft")).to be false
  end

  it "draft state is unchanged if not a draft comment" do
    result = run_mutation(submission_comment_id: @teacher_comment.id)
    expect(result.dig("data", "postDraftSubmissionComment", "submissionComment", "draft")).to be false
  end

  it "teacher cannot update a student comment" do
    result = run_mutation(submission_comment_id: @student_draft_comment.id)
    expect(result[:errors][0][:message]).to eq "Not authorized to update SubmissionComment"
  end

  it "student cannot update a teacher comment" do
    result = run_mutation({ submission_comment_id: @teacher_draft_comment.id }, @student)
    expect(result[:errors][0][:message]).to eq "Not authorized to update SubmissionComment"
  end
end
