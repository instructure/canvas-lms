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

RSpec.describe Mutations::UpdateSubmissionGrade do
  def mutation_str(submission_id: nil, late_policy_status: nil, custom_grade_status_id: nil)
    late_policy_status = late_policy_status ? "\"#{late_policy_status}\"" : "null"
    custom_grade_status_id = custom_grade_status_id ? "\"#{custom_grade_status_id}\"" : "null"
    <<~GQL
      mutation {
        updateSubmissionGradeStatus(
          input: {
            submissionId: #{submission_id}
            latePolicyStatus: #{late_policy_status}
            customGradeStatusId: #{custom_grade_status_id}
          }
        ) {
          submission {
            _id
            id
            userId
            assignmentId
            gradingStatus
            latePolicyStatus
            customGradeStatus
            excused
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
    result = CanvasSchema.execute(mutation_str(**opts), context: { current_user:, request: ActionDispatch::TestRequest.create })
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

  it "can update a submission grade status" do
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "late", custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to eq "late"
  end

  it "can update a submission grade status with custom grade status" do
    custom_grade_status = CustomGradeStatus.create!(name: "custom", color: "#000000", root_account_id: @course.root_account, created_by: @teacher)
    result = run_mutation({ submission_id: @submission.id, custom_grade_status_id: custom_grade_status.id })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq custom_grade_status.name.to_s
  end

  it "user should not have access to grade" do
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "late", custom_grade_status_id: nil }, @student)
    expect(result[:data][:updateSubmissionGradeStatus][:submission]).to be_nil
    expect(result[:data][:updateSubmissionGradeStatus][:errors]).to include({ attribute: @submission.id.to_s, message: "Not authorized to set submission status" })
  end

  it "set status to extended" do
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "extended", custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to eq "extended"
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq ""
  end

  it "set status to nil if none" do
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "none", custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to eq "none"
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq ""
  end

  it "sets status and custom id to nil if no status is provided or custom id is provided" do
    result = run_mutation({ submission_id: @submission.id, late_policy_status: nil, custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to be_nil
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq ""
  end

  it "sets excused status" do
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "excused", custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to be_nil
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq ""
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:excused]).to be true
  end

  it "overwrites excused with no status" do
    @submission.update!(excused: true)
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "none", custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to eq "none"
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq ""
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:excused]).to be false
  end

  it "overwrites excused with custom grade status" do
    @submission.update!(excused: true)
    custom_grade_status = CustomGradeStatus.create!(name: "custom", color: "#000000", root_account_id: @course.root_account, created_by: @teacher)
    result = run_mutation({ submission_id: @submission.id, custom_grade_status_id: custom_grade_status.id })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to be_nil
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq custom_grade_status.name.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:excused]).to be false
  end

  it "overwrites excused with late policy status" do
    @submission.update!(excused: true)
    result = run_mutation({ submission_id: @submission.id, late_policy_status: "late", custom_grade_status_id: nil })
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:_id]).to eq @submission.id.to_s
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:latePolicyStatus]).to eq "late"
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:customGradeStatus]).to eq ""
    expect(result[:data][:updateSubmissionGradeStatus][:submission][:excused]).to be false
  end
end
