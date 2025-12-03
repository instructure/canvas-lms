# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
require_relative "../../apis/api_spec_helper"

RSpec.describe "UpdateSubmissionGradeStatus vs SubmissionsApiController#update", type: :request do
  include Api

  describe "comparing GraphQL mutation with REST API for submission status updates" do
    before(:once) do
      @account = Account.create!
      @course = @account.courses.create!
      @teacher = @course.enroll_teacher(User.create!, enrollment_state: "active").user
      @assignment = @course.assignments.create!(title: "Test Assignment", points_possible: 10)

      # Create two students - one for GraphQL, one for REST API
      @graphql_student = @course.enroll_student(User.create!, enrollment_state: "active").user
      @rest_student = @course.enroll_student(User.create!, enrollment_state: "active").user
    end

    before do
      user_session(@teacher)

      # Create fresh submissions for each test
      @graphql_submission = @assignment.submit_homework(
        @graphql_student,
        submission_type: "online_text_entry",
        body: "graphql test submission"
      )
      @rest_submission = @assignment.submit_homework(
        @rest_student,
        submission_type: "online_text_entry",
        body: "rest test submission"
      )
    end

    def graphql_mutation(submission_id:, late_policy_status: nil, custom_grade_status_id: nil)
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

    def run_graphql_mutation(opts = {}, current_user = @teacher)
      result = CanvasSchema.execute(
        graphql_mutation(**opts),
        context: { current_user:, request: ActionDispatch::TestRequest.create }
      )
      result.to_h.with_indifferent_access
    end

    def rest_api_update(submission_params, student = @rest_student, user = @teacher)
      @user = user
      api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}",
        {
          controller: "submissions_api",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: student.id.to_s
        },
        { submission: submission_params }
      )
    end

    def compare_submissions(graphql_sub, rest_sub, expected_differences: {})
      comparison = {
        late_policy_status: {
          graphql: graphql_sub.late_policy_status,
          rest: rest_sub.late_policy_status
        },
        missing: {
          graphql: graphql_sub.missing,
          rest: rest_sub.missing
        },
        late: {
          graphql: graphql_sub.late,
          rest: rest_sub.late
        },
        excused: {
          graphql: graphql_sub.excused,
          rest: rest_sub.excused
        },
        graded_at: {
          graphql: graphql_sub.graded_at.present?,
          rest: rest_sub.graded_at.present?
        },
        posted_at: {
          graphql: graphql_sub.posted_at.present?,
          rest: rest_sub.posted_at.present?
        },
        score: {
          graphql: graphql_sub.score,
          rest: rest_sub.score
        },
        grader_id: {
          graphql: graphql_sub.grader_id,
          rest: rest_sub.grader_id
        },
        custom_grade_status_id: {
          graphql: graphql_sub.custom_grade_status_id,
          rest: rest_sub.custom_grade_status_id
        }
      }

      # Check expected differences
      expected_differences.each do |field, expected_values|
        expect(comparison[field][:graphql]).to eq(expected_values[:graphql]),
                                               "GraphQL #{field} should be #{expected_values[:graphql].inspect}"
        expect(comparison[field][:rest]).to eq(expected_values[:rest]),
                                            "REST #{field} should be #{expected_values[:rest].inspect}"
      end

      # Check that all other fields match
      (comparison.keys - expected_differences.keys).each do |field|
        expect(comparison[field][:graphql]).to eq(comparison[field][:rest]),
                                               "Expected #{field} to match but GraphQL=#{comparison[field][:graphql].inspect} and REST=#{comparison[field][:rest].inspect}"
      end

      comparison
    end

    def validate_grader(graphql_sub, rest_sub)
      expect(graphql_sub.grader_id).to eq @teacher.id
      expect(rest_sub.grader_id).to eq @teacher.id
    end

    context "authorization" do
      it "GraphQL returns error object, REST returns error status" do
        # Test with student trying to update their own submission status
        # GraphQL approach
        graphql_result = run_graphql_mutation(
          { submission_id: @graphql_submission.id, late_policy_status: "late" },
          @graphql_student
        )
        expect(graphql_result.dig(:data, :updateSubmissionGradeStatus, :submission)).to be_nil
        expect(graphql_result.dig(:data, :updateSubmissionGradeStatus, :errors)).to be_present

        # REST API approach
        @user = @rest_student
        raw_api_call(
          :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@rest_student.id}",
          {
            controller: "submissions_api",
            action: "update",
            format: "json",
            course_id: @course.id.to_s,
            assignment_id: @assignment.id.to_s,
            user_id: @rest_student.id.to_s
          },
          { submission: { late_policy_status: "late" } }
        )
        # REST API returns 403 Forbidden when student tries to set status
        expect(response).to have_http_status(:forbidden)
      end
    end

    shared_examples "submission status updates" do |expected_posted_at_set: false, expected_missing_posted_at_set: false|
      context "setting late_policy_status to 'late'" do
        it "produces identical states" do
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "late")
          rest_api_update({ late_policy_status: "late" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)
        end
      end

      context "setting late_policy_status to 'missing'" do
        it "produces identical states" do
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "missing")
          rest_api_update({ late_policy_status: "missing" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.posted_at.present?).to be expected_missing_posted_at_set
          expect(@rest_submission.posted_at.present?).to be expected_missing_posted_at_set
        end
      end

      context "setting late_policy_status to 'extended'" do
        it "produces identical states" do
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "extended")
          rest_api_update({ late_policy_status: "extended" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)
        end
      end

      context "setting late_policy_status to 'none'" do
        it "produces identical states" do
          # Set initial late status
          @graphql_submission.update!(late_policy_status: "late")
          @rest_submission.update!(late_policy_status: "late")

          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "none")
          rest_api_update({ late_policy_status: "none" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          # Both should have status "none" and excused false
          expect(@graphql_submission.late_policy_status).to eq "none"
          expect(@rest_submission.late_policy_status).to eq "none"
          expect(@graphql_submission.excused).to be false
          expect(@rest_submission.excused).to be false
        end
      end

      context "excusing submissions" do
        it "produces identical excused states with different approaches" do
          # GraphQL uses late_policy_status: "excused"
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "excused")

          # REST API uses excuse: true parameter
          rest_api_update({ excuse: true })

          # Both should have excused=true, but graded_at and posted_at may differ
          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.excused).to be true
          expect(@rest_submission.excused).to be true
          expect(@graphql_submission.late_policy_status).to be_nil
          expect(@rest_submission.late_policy_status).to be_nil

          expect(@graphql_submission.posted_at.present?).to be expected_posted_at_set
          expect(@rest_submission.posted_at.present?).to be expected_posted_at_set
        end
      end

      context "setting custom_grade_status_id" do
        before(:once) do
          @custom_status = CustomGradeStatus.create!(
            name: "Needs Revision",
            color: "#FF0000",
            root_account_id: @account.id,
            created_by: @teacher
          )
        end

        it "produces identical states" do
          run_graphql_mutation(
            submission_id: @graphql_submission.id,
            custom_grade_status_id: @custom_status.id
          )
          rest_api_update({ custom_grade_status_id: @custom_status.id })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.custom_grade_status_id).to eq @custom_status.id
          expect(@rest_submission.custom_grade_status_id).to eq @custom_status.id
        end
      end

      context "clearing statuses with late_policy_status 'none'" do
        it "clears custom_grade_status_id for both implementations" do
          custom_status = CustomGradeStatus.create!(
            name: "Test",
            color: "#00FF00",
            root_account_id: @account.id,
            created_by: @teacher
          )

          @graphql_submission.update!(custom_grade_status_id: custom_status.id)
          @rest_submission.update!(custom_grade_status_id: custom_status.id)

          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "none")
          rest_api_update({ late_policy_status: "none" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.custom_grade_status_id).to be_nil
          expect(@rest_submission.custom_grade_status_id).to be_nil
        end
      end

      context "overwriting excused status" do
        it "both implementations clear excused when setting late_policy_status" do
          # Properly excuse both submissions first
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "excused")
          rest_api_update({ excuse: true })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          expect(@graphql_submission.excused).to be true
          expect(@rest_submission.excused).to be true

          expect(@graphql_submission.posted_at.present?).to be expected_posted_at_set
          expect(@rest_submission.posted_at.present?).to be expected_posted_at_set

          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "late")
          rest_api_update({ late_policy_status: "late" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.excused).to be false
          expect(@rest_submission.excused).to be false

          expect(@graphql_submission.posted_at.present?).to be expected_posted_at_set
          expect(@rest_submission.posted_at.present?).to be expected_posted_at_set
        end

        it "both implementations clear excused properly when setting late_policy_status to 'late'" do
          # Set excused via GraphQL
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "excused")
          # Set excused via REST API
          rest_api_update({ excuse: true })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.excused).to be true
          expect(@rest_submission.excused).to be true
          expect(@graphql_submission.late_policy_status).to be_nil
          expect(@rest_submission.late_policy_status).to be_nil

          expect(@graphql_submission.posted_at.present?).to be expected_posted_at_set
          expect(@rest_submission.posted_at.present?).to be expected_posted_at_set

          # Set submissions late
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "late")
          rest_api_update({ late_policy_status: "late" })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          expect(@graphql_submission.excused).to be false
          expect(@rest_submission.excused).to be false
          expect(@graphql_submission.late_policy_status).to eq "late"
          expect(@rest_submission.late_policy_status).to eq "late"

          expect(@graphql_submission.posted_at.present?).to be expected_posted_at_set
          expect(@rest_submission.posted_at.present?).to be expected_posted_at_set
        end

        it "both implementations clear excused when setting custom_grade_status" do
          custom_status = CustomGradeStatus.create!(
            name: "Test",
            color: "#00FF00",
            root_account_id: @account.id,
            created_by: @teacher
          )

          # Properly excuse both submissions first
          run_graphql_mutation(submission_id: @graphql_submission.id, late_policy_status: "excused")
          rest_api_update({ excuse: true })

          # Both should have excused=true, but graded_at and posted_at may differ
          @graphql_submission.reload
          @rest_submission.reload

          run_graphql_mutation(
            submission_id: @graphql_submission.id,
            custom_grade_status_id: custom_status.id
          )
          rest_api_update({ custom_grade_status_id: custom_status.id })

          @graphql_submission.reload
          @rest_submission.reload

          compare_submissions(@graphql_submission, @rest_submission)

          validate_grader(@graphql_submission, @rest_submission)

          expect(@graphql_submission.excused).to be false
          expect(@rest_submission.excused).to be false
        end
      end
    end

    shared_examples "missing and late deductions variations" do |expected_posted_at_set: false|
      context "without missing and late deductions" do
        before do
          @course.create_late_policy(
            missing_submission_deduction_enabled: false,
            late_submission_deduction_enabled: false
          )
        end

        include_examples "submission status updates", expected_posted_at_set:, expected_missing_posted_at_set: false
      end

      context "with missing deductions but without late deductions" do
        before do
          @course.create_late_policy(
            missing_submission_deduction_enabled: true,
            missing_submission_deduction: 50,
            late_submission_deduction_enabled: false
          )
        end

        include_examples "submission status updates", expected_posted_at_set:, expected_missing_posted_at_set: expected_posted_at_set
      end

      context "without missing deductions but with late deductions" do
        before do
          @course.create_late_policy(
            missing_submission_deduction_enabled: false,
            late_submission_deduction_enabled: true,
            late_submission_deduction: 10,
            late_submission_interval: "day"
          )
        end

        include_examples "submission status updates", expected_posted_at_set:, expected_missing_posted_at_set: false
      end

      context "with missing and late deductions" do
        before do
          @course.create_late_policy(
            missing_submission_deduction_enabled: true,
            late_submission_deduction_enabled: true,
            late_submission_deduction: 10,
            late_submission_interval: "day"
          )
        end

        include_examples "submission status updates", expected_posted_at_set:, expected_missing_posted_at_set: expected_posted_at_set
      end
    end

    context "with automatic grade posting enabled" do
      before do
        @assignment.ensure_post_policy(post_manually: false)
      end

      it "initial validations" do
        expect(@graphql_submission.posted_at).to be_nil
        expect(@rest_submission.posted_at).to be_nil

        expect(@assignment.post_manually?).to be false
      end

      include_examples "missing and late deductions variations", expected_posted_at_set: true
    end

    context "with automatic grade posting disabled" do
      before do
        @assignment.ensure_post_policy(post_manually: true)
      end

      it "initial validations" do
        expect(@graphql_submission.posted_at).to be_nil
        expect(@rest_submission.posted_at).to be_nil

        expect(@assignment.post_manually?).to be true
      end

      include_examples "missing and late deductions variations", expected_posted_at_set: false
    end
  end
end
