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

describe Mutations::DeleteSubmissionComment do
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

  def mutation_str(submission_comment_id: nil)
    <<~GQL
      mutation {
        deleteSubmissionComment(input: {
          submissionCommentId: #{submission_comment_id}
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
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @teacher)
    result = CanvasSchema.execute(mutation_str(**opts), context: { current_user: })
    result.to_h.with_indifferent_access
  end

  it "deletes an existing comment on the specified submission" do
    comment = @submission.add_comment({ author: @teacher, comment: "hello" })
    result = run_mutation({ submission_comment_id: comment.id })
    expect(result.dig(:data, :deleteSubmissionComment, :submissionComment, :comment)).to eq "hello"
    expect(SubmissionComment.where(id: comment.id)).to match([])
  end

  it "returns an error if the comment does not exist" do
    result = run_mutation({ submission_comment_id: 0 })
    expect(result[:errors][0][:message]).to eq "Not authorized to delete SubmissionComment"
  end

  it "returns an error if the user is not authorized to delete the comment" do
    comment = @submission.add_comment({ author: @teacher, comment: "hello" })
    result = run_mutation({ submission_comment_id: comment.id }, @student)
    expect(result[:errors][0][:message]).to eq "Not authorized to delete SubmissionComment"
  end
end
