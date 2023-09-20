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

RSpec.describe Mutations::UpdateSubmissionStudentEnteredScore do
  def mutation_str(
    id: "",
    entered_score: nil
  )
    <<~GQL
      mutation {
        updateSubmissionStudentEnteredScore(input: { submissionId: #{id}, enteredScore: #{entered_score} }) {
          submission {
            _id
            studentEnteredScore
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
  end

  it "updates the student entered score" do
    expect(@submission.student_entered_score).to be_nil
    result = run_mutation(id: @submission.id, entered_score: 5)
    expect(result[:data][:updateSubmissionStudentEnteredScore][:submission][:_id]).to eq(@submission.id.to_s)
    expect(result[:data][:updateSubmissionStudentEnteredScore][:submission][:studentEnteredScore]).to eq(@submission.reload.student_entered_score)
    expect(@submission.reload.student_entered_score).to eq(5)
  end

  it "returns the updated submissions" do
    result = run_mutation(id: @submission.id, entered_score: 5)
    expect(result[:data][:updateSubmissionStudentEnteredScore][:submission][:_id]).to eq(@submission.id.to_s)
  end

  it "returns an error if the user is not authorized to read the submission" do
    result = run_mutation(id: "0", entered_score: 5)
    expect(result[:data][:updateSubmissionStudentEnteredScore][:errors][0][:message]).to eq("Submission not found")
  end
end
