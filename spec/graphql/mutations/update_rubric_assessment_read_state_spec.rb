# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

RSpec.describe Mutations::UpdateRubricAssessmentReadState do
  def mutation_str(
    ids: []
  )
    <<~GQL
      mutation {
        updateRubricAssessmentReadState(input: {submissionIds: #{ids}}) {
          submissions {
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
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
    @assessment = @association.assess({
                                        user: @student,
                                        assessor: @teacher,
                                        artifact: @submission,
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: 5,
                                            comments: "comments",
                                          }
                                        }
                                      })
  end

  it "creates an unread content participation" do
    expect(@submission.unread_item?(@student, "rubric")).to be_truthy
  end

  it "marks the content participation as read" do
    result = run_mutation({ ids: [@submission.id] })

    expect(result.dig("data", "updateRubricAssessmentReadState", "errors")).to be_nil
    expect(result.dig("data", "updateRubricAssessmentReadState", "submissions")).to include({ _id: @submission.id.to_s })
    expect(@submission.unread_item?(@student, "rubric")).to be_falsey
  end

  describe "error handling" do
    it "returns a list of submissions not found" do
      submission_id_that_does_not_exist = "555"
      result = run_mutation({ ids: [submission_id_that_does_not_exist, @submission.id] })

      expect(result.dig("data", "updateRubricAssessmentReadState", "errors")).not_to be_nil
      expect(result.dig("data", "updateRubricAssessmentReadState", "submissions")).to include({ _id: @submission.id.to_s })
      expect(result.dig("data", "updateRubricAssessmentReadState", "errors")).to include({ attribute: submission_id_that_does_not_exist, message: "Unable to find Submission" })
    end
  end
end
