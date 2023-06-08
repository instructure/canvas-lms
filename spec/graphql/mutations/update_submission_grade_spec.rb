# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

RSpec.describe Mutations::UpdateSubmissionGrade do
  def mutation_str(submission_id: nil, score: nil)
    <<~GQL
      mutation {
        updateSubmissionGrade(input: {submissionId: #{submission_id}, score: #{score}}) {
          submission {
            _id
            id
            grade
            score
            user {
              _id
              id
              name
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
    @teacher_comment = @submission.submission_comments.create!(author: @teacher, comment: "teachers whats up")
  end

  it "updates grade to 12" do
    result = run_mutation({ submission_id: @submission.id, score: 12 })
    expect(result.dig("data", "updateSubmissionGrade", "errors")).to be_nil
    expect(result.dig("data", "updateSubmissionGrade", "submission")).to include({ _id: @submission.id.to_s })
    @submission.reload
    expect(@submission.score).to eq 12
  end

  it "user should not have access to grade" do
    result = run_mutation({ submission_id: @submission.id, score: 12 }, @student)
    errors = result.dig("data", "updateSubmissionGrade", "errors")
    expect(result.dig("data", "updateSubmissionGrade", "submission")).to be_nil
    expect(errors).not_to be_nil
    @submission.reload
    expect(@submission.score).to be_nil
    expect(errors[0][:message]).to eq "Not authorized to score Submission"
  end
end
