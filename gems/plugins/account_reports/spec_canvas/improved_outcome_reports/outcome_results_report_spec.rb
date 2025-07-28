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

require_relative "../report_spec_helper"
require_relative "shared/shared_examples"
require_relative "shared/improved_outcome_reports_spec_helpers"
require_relative "shared/setup"

describe "OutcomeResultsReport" do
  include ReportSpecHelper
  include ImprovedOutcomeReportsSpecHelpers

  include_context "setup"

  let(:report_type) { "outcome_results_csv" }
  let(:expected_headers) { AccountReports::ImprovedOutcomeReports::OutcomeResultsReport::HEADERS }
  let(:all_values) { [user1_values] }
  let(:order) { [0, 2, 3, 13, 18] }

  include_examples "common outcomes report behavior"

  context "with quiz question results" do
    before(:once) do
      @outcome_group = @root_account.root_outcome_group
      @quiz_outcome = @root_account.created_learning_outcomes.create!(short_description: "new outcome")
      @quiz = @course1.quizzes.create!(title: "quiz", shuffle_answers: true, quiz_type: "assignment")
      @q1 = @quiz.quiz_questions.create!(question_data: true_false_question_data)
      @q2 = @quiz.quiz_questions.create!(question_data: multiple_choice_question_data)
      bank = @q1.assessment_question.assessment_question_bank
      bank.assessment_questions.create!(question_data: true_false_question_data)
      @quiz_outcome.align(bank, @root_account, mastery_score: 0.7)
      answer_1 = @q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      answer_2 = @q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(persist: true)
      @quiz_submission = @quiz.generate_submission(@user)
      @quiz_submission.submission_data = {}
      @quiz_submission.submission_data["question_#{@q1.id}"] = answer_1
      @quiz_submission.submission_data["question_#{@q2.id}"] = answer_2 + 1
      Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
      @quiz_outcome.reload
      @outcome_group.add_outcome(@quiz_outcome)
      @quiz_outcome_result = LearningOutcomeResult.find_by(artifact: @quiz_submission)
      @new_quiz = @course1.assignments.create!(title: "New Quiz", submission_types: "external_tool")
      @new_quiz_submission = @new_quiz.grade_student(@user1, grade: "10", grader: @teacher).first
      @new_quiz_submission.submission_type = "basic_lti_launch"
      @new_quiz_submission.submitted_at = 1.week.ago
      @new_quiz_submission.save!
    end

    it "works with quizzes" do
      common_quiz_values = {
        user: @user2,
        quiz: @quiz,
        quiz_submission: @quiz_submission,
        outcome: @quiz_outcome,
        outcome_group: @outcome_group,
        course: @course1,
        assignment: @quiz.assignment,
        section: @section,
        quiz_outcome_result: @quiz_outcome_result
      }
      verify_all(
        report, [
          {
            **common_quiz_values,
            question: @q1.assessment_question,
            outcome_result: LearningOutcomeQuestionResult.find_by(
              learning_outcome_result: @quiz_outcome_result,
              associated_asset: @q1.assessment_question
            )
          },
          {
            **common_quiz_values,
            question: @q2.assessment_question,
            outcome_result: LearningOutcomeQuestionResult.find_by(
              learning_outcome_result: @quiz_outcome_result,
              associated_asset: @q2.assessment_question
            )
          },
          user1_values
        ]
      )
    end

    it "includes ratings for quiz questions" do
      expect(report[0]["assessment type"]).to eq "quiz"
      expect(report[0]["learning outcome rating"]).to eq "Does Not Meet Expectations"
    end

    context "Report does not include results" do
      let(:account_report) { AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1) }
      let(:outcome_reports) { AccountReports::ImprovedOutcomeReports::OutcomeResultsReport.new(account_report) }
      let(:assignment_ids) { @new_quiz.id.to_s }
      let(:outcome_ids) { @outcome.id.to_s }
      let(:uuids) { "#{@user1.uuid},#{@user2.uuid}" }

      it "when assignment is deleted" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        @new_quiz.destroy
        # OS will not be called because there are no new quizzes
        expect(outcome_reports).not_to receive(:get_lmgb_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        expect(results.length).to eq(0)
      end
    end

    context "ordering param" do
      def validate_outcome_ordering(outcome_report, expected_result)
        expected_result = nil unless AccountReports::ImprovedOutcomeReports::OutcomeResultsReport::ORDER_OPTIONS.include? expected_result
        add_text_calls = expected_result.nil? ? 0 : 1

        expect(outcome_report).to receive(:add_extra_text).exactly(add_text_calls).time
        outcome_report.send(:add_outcome_order_text)

        expect(outcome_report.send(:determine_order_key)).to eq expected_result

        # default ordering is users
        expected_result = "users" if expected_result.nil?
        expect(outcome_report.send(:outcome_order)).to eq AccountReports::ImprovedOutcomeReports::OutcomeResultsReport::ORDER_SQL[expected_result]
      end

      it "order key is valid" do
        test_cases = %w[users courses outcomes USERS COURSES OUTCOMES Users usErS foo bar]
        test_cases.each do |test|
          account_report = AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1)
          account_report.parameters = { "order" => test }
          outcome_report = AccountReports::ImprovedOutcomeReports::OutcomeResultsReport.new(account_report)
          validate_outcome_ordering(outcome_report, test.downcase)
        end
      end

      it "order key is nil if ordering is not present" do
        account_report = AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1)
        outcome_report = AccountReports::ImprovedOutcomeReports::OutcomeResultsReport.new(account_report)
        validate_outcome_ordering(outcome_report, nil)
      end
    end

    context ":outcome_service_results_to_canvas - when outcomes service fails" do
      before do
        settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
        @root_account.settings[:provision] = { "outcomes" => settings }
        @root_account.save!
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
      end

      after do
        @root_account.settings[:provision] = nil
        @root_account.save!
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "off")
      end

      it "errors the report" do
        expect(CanvasHttp).to receive(:get).and_raise("failed call").exactly(3).times
        report_record = run_report(report_type, account: @root_account, params: { "include_deleted" => true })
        expect(report_record.workflow_state).to eq "error"
        expect(report_record.message).to start_with "Generating the report, Outcome Results CSV, failed."
        expect(report_record.parameters["extra_text"]).to eq "Failed, the report failed to generate a file. Please try again."
      end
    end

    context ":outcome_service_results_to_canvas - json parsing" do
      before do
        settings = { consumer_key: "key", jwt_secret: "secret", domain: "domain" }
        @root_account.settings[:provision] = { "outcomes" => settings }
        @root_account.save!
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
      end

      after do
        @root_account.settings[:provision] = nil
        @root_account.save!
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "off")
      end

      def json_string_null_metadata(asset_id)
        {
          results: [
            {
              associated_asset_id: asset_id,
              associated_asset_type: "canvas.assignment.quizzes",
              attempts: [
                {
                  points: 1,
                  points_possible: 2
                }
              ]
            }
          ]
        }.to_json
      end

      it "can handle null metadata" do
        response = Net::HTTPSuccess.new(1.1, 200, "OK")
        expect(response).to receive(:body).and_return(json_string_null_metadata(@new_quiz.id))
        expect(response).to receive(:header).and_return({ "Per-Page" => "200", "Total" => 1 }).twice
        expect(CanvasHttp).to receive(:get).with(any_args).and_return(response).once

        report_record = run_report(report_type, account: @root_account, params: { "include_deleted" => true })
        expect(report_record.workflow_state).to eq "complete"
        expect(report_record.message).to eq "Outcome Results report successfully generated with the following settings. Account: New Account; Term: All Terms; Include Deleted/Concluded Objects;"
        expect(report_record.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted/Concluded Objects;"
      end

      it "errors if not valid json" do
        response = Net::HTTPSuccess.new(1.1, 200, "OK")
        # once for parsing and then once for throwing the error
        expect(response).to receive(:body).and_return("not_valid_json").twice
        expect(response).to receive(:header).and_return({ "Per-Page" => "200", "Total" => 0 }).twice
        expect(CanvasHttp).to receive(:get).with(any_args).and_return(response).once

        report_record = run_report(report_type, account: @root_account, params: { "include_deleted" => true })
        expect(report_record.workflow_state).to eq "error"
        expect(report_record.message).to start_with "Generating the report, Outcome Results CSV, failed."
        expect(report_record.parameters["extra_text"]).to eq "Failed, the report failed to generate a file. Please try again."
      end
    end

    context ":outcome_service_results_to_canvas" do
      # Column indexes
      student_name = 0
      assessment_title = 3
      assessment_type = 5
      outcome = 8
      question = 12
      question_id = 13
      course = 14

      # These columns are added/modified to the report when writing the csv file
      outcome_score = 11
      learning_outcome_points_possible = 22
      learning_outcome_mastery_score = 23
      learning_outcome_mastered = 24
      learning_outcome_rating = 25
      learning_outcome_rating_points = 26

      def mock_os_result(user, outcome, quiz, submission_date, attempts = nil)
        if attempts.nil?
          attempts = [
            { id: 2,
              authoritative_result_id: 2,
              points: 1.0,
              points_possible: 1.0,
              metadata: {
                quiz_metadata: {
                  quiz_title: "Quiz Title",
                  quiz_id: quiz.id,
                  points: 1.0,
                  points_possible: 1.0
                }
              } }
          ]
        end

        [{ user_uuid: user.uuid,
           external_outcome_id: outcome.id,
           associated_asset_id: quiz.id,
           attempts:,
           percent_score: 1.0,
           points: 5.0,
           points_possible: 5.0,
           submitted_at: submission_date,
           mastery: nil },]
      end

      let(:account_report) { AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1) }
      let(:outcome_reports) { AccountReports::ImprovedOutcomeReports::OutcomeResultsReport.new(account_report) }
      let(:assignment_ids) { @new_quiz.id.to_s }
      let(:outcome_ids) { @outcome.id.to_s }
      let(:uuids) { "#{@user1.uuid},#{@user2.uuid}" }

      it "does not call OS when FF is off for the account" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "off")

        expect(outcome_reports).not_to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        expect(results).to be_empty
      end

      it "does not call OS when FF is off for course" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        @course1.set_feature_flag!(:outcome_service_results_to_canvas, "off")

        # get_lmgb_results is still called, but the first line checks is the FF is enabled and returns nil if OFF
        # In that case, get_lmgb_results returns nil
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        expect(results).to be_empty
      end

      it "filters out users that do not have results" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")

        # uuids contains both @user1 and @user2. The mock result only contains data for @user1, so @user2
        # will not show up in the report.
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z"))
        results = outcome_reports.send(:outcomes_new_quiz_scope)

        # mock_os_result returns a result that has quiz metadata, but no question meta data. This means that
        # learning outcome points possible and outcome score will be from the authoritative result.

        expect(results.length).to eq(1)
        expect(results[0]["student uuid"]).to eq @user1.uuid
        expect(results[0]["learning outcome points possible"]).to eq 5.0
        expect(results[0]["outcome score"]).to eq 5.0
        expect(results[0]["attempt"]).to eq 1
      end

      it "includes users that do not have attempts" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z", []))
        results = outcome_reports.send(:outcomes_new_quiz_scope)

        expect(results.length).to eq(1)
        expect(results[0]["student uuid"]).to eq @user1.uuid
        expect(results[0]["learning outcome points possible"]).to eq 5.0
        expect(results[0]["outcome score"]).to eq 5.0
        expect(results[0]["attempt"]).to eq 1
      end

      it "keeps the result with the latest submission date" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z", [
                                        { id: 2,
                                          authoritative_result_id: 2,
                                          points: 1.0,
                                          points_possible: 1.0,
                                          metadata: {
                                            question_metadata: [{
                                              quiz_item_title: "Newer Submission",
                                              quiz_item_id: @new_quiz.id,
                                              points: 1.0,
                                              points_possible: 1.0
                                            }]
                                          } }
                                      ]).concat(mock_os_result(@user1, @outcome, @new_quiz, "2022-08-19T12:00:00.0Z", [
                                                                 { id: 2,
                                                                   authoritative_result_id: 2,
                                                                   points: 1.0,
                                                                   points_possible: 1.0,
                                                                   metadata: {
                                                                     question_metadata: [{
                                                                       quiz_item_title: "Older Submission",
                                                                       quiz_item_id: @new_quiz.id,
                                                                       points: 1.0,
                                                                       points_possible: 1.0
                                                                     }]
                                                                   } }
                                                               ]))
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        expect(results.length).to eq(1)
        expect(results[0]["student uuid"]).to eq @user1.uuid
        expect(results[0]["assessment question"]).to eq "Newer Submission"
        expect(results[0]["attempt"]).to eq 1
      end

      it "returns points on authoritative result if missing metadata" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z", [
                                        { id: 2,
                                          authoritative_result_id: 2,
                                          points: 7.0,
                                          points_possible: 21.0, }
                                      ])
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        expect(results.length).to eq(1)
        expect(results[0]["student uuid"]).to eq @user1.uuid
        expect(results[0]["learning outcome points possible"]).to eq 5.0
        expect(results[0]["outcome score"]).to eq 5.0
      end

      it "will use submitted_at instead of created_at if present" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z", [
                                        { id: 1,
                                          authoritative_result_id: 2,
                                          points: 2.0,
                                          points_possible: 2.0,
                                          submitted_at: "2022-08-20T12:00:00.0Z", # This date will be used to compare with other attempt
                                          created_at: "2023-08-19T12:00:00.0Z", # This date will be ignored
                                          metadata: {
                                            question_metadata: [
                                              {
                                                quiz_item_id: "1",
                                                quiz_item_title: "Attempt 1 Question 1",
                                                points: 0.0,
                                                points_possible: 1.0
                                              },
                                              {
                                                quiz_item_id: "2",
                                                quiz_item_title: "Attempt 1 Question 2",
                                                points: 1.0,
                                                points_possible: 2.0
                                              }
                                            ]
                                          } },
                                        { id: 2,
                                          authoritative_result_id: 2,
                                          points: 2.0,
                                          points_possible: 2.0,
                                          submitted_at: "2022-08-19T12:00:00.0Z", # This date will be used to compare with other attempt
                                          created_at: "2023-08-20T12:00:00.0Z", # This date will be ignored
                                          metadata: {
                                            question_metadata: [
                                              {
                                                quiz_item_id: "3",
                                                quiz_item_title: "Attempt 2 Question 1",
                                                points: 2.0,
                                                points_possible: 3.0
                                              },
                                              {
                                                quiz_item_id: "4",
                                                quiz_item_title: "Attempt 2 Question 2",
                                                points: 3.0,
                                                points_possible: 4.0
                                              }
                                            ]
                                          } }
                                      ])
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)

        expect(results.length).to eq(2)
        results.each_index do |i|
          expect(results[i]["student uuid"]).to eq @user1.uuid
          expect(results[i]["student name"]).to eq @user1.sortable_name
          expect(results[i]["assignment id"]).to eq @new_quiz.id
          expect(results[i]["assessment title"]).to eq @new_quiz.title
          expect(results[i]["assessment id"]).to eq @new_quiz.id
          expect(results[i]["submission date"]).to eq @new_quiz_submission.submitted_at
          expect(results[i]["submission score"]).to eq @new_quiz_submission&.grade&.to_f
          expect(results[i]["learning outcome name"]).to eq @outcome.short_description
          expect(results[i]["learning outcome id"]).to eq @outcome.id
          expect(results[i]["learning outcome friendly name"]).to eq @outcome.display_name
          expect(results[i]["learning outcome mastered"]).to be false
          expect(results[i]["learning outcome data"]).to eq @outcome.data.to_yaml
          expect(results[i]["learning outcome group title"]).to eq @outcome_group.title
          expect(results[i]["learning outcome group id"]).to eq @outcome_group.id

          # 2 attempts were returned so we are looking at 1st attempt
          expect(results[i]["attempt"]).to eq(2)
          expect(results[i]["learning outcome points hidden"]).to be_nil

          # These equation just make sure we are looking at data from 1st attempt
          expect(results[i]["outcome score"]).to eq i
          expect(results[i]["learning outcome points possible"]).to eq(i + 1)
          expect(results[i]["assessment question id"]).to eq((i + 1).to_s)
          expect(results[i]["assessment question"]).to eq "Attempt 1 Question #{i + 1}"

          expect(results[i]["total percent outcome score"]).to eq 1.0
          expect(results[i]["course name"]).to eq @course1.name
          expect(results[i]["course id"]).to eq @course1.id
          expect(results[i]["course sis id"]).to eq @course1.sis_source_id
          expect(results[i]["assessment type"]).to eq "quiz"
          expect(results[i]["section name"]).to eq @section.name
          expect(results[i]["section id"]).to eq @section.id
          expect(results[i]["section sis id"]).to eq @section.sis_source_id
          expect(results[i]["enrollment state"]).to eq @enrollment1.workflow_state
          expect(results[i]["account id"]).to eq @root_account.id
          expect(results[i]["account name"]).to eq @root_account.name
        end
      end

      it "will use submitted_at or created_at if inconsistently populated" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z", [
                                        { id: 1,
                                          authoritative_result_id: 2,
                                          points: 2.0,
                                          points_possible: 2.0,
                                          submitted_at: "2023-08-20T12:00:00.0Z", # This date will be used to compare with other attempt
                                          created_at: "2022-08-19T12:00:00.0Z", # This date will be ignored
                                          metadata: {
                                            question_metadata: [
                                              {
                                                quiz_item_id: "1",
                                                quiz_item_title: "Attempt 1 Question 1",
                                                points: 0.0,
                                                points_possible: 1.0
                                              },
                                              {
                                                quiz_item_id: "2",
                                                quiz_item_title: "Attempt 1 Question 2",
                                                points: 1.0,
                                                points_possible: 2.0
                                              }
                                            ]
                                          } },
                                        { id: 2,
                                          authoritative_result_id: 2,
                                          points: 2.0,
                                          points_possible: 2.0,
                                          created_at: "2022-08-20T12:00:00.0Z", # This date will be used to compare with other attempt
                                          metadata: {
                                            question_metadata: [
                                              {
                                                quiz_item_id: "3",
                                                quiz_item_title: "Attempt 2 Question 1",
                                                points: 2.0,
                                                points_possible: 3.0
                                              },
                                              {
                                                quiz_item_id: "4",
                                                quiz_item_title: "Attempt 2 Question 2",
                                                points: 3.0,
                                                points_possible: 4.0
                                              }
                                            ]
                                          } }
                                      ])
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)

        expect(results.length).to eq(2)
        results.each_index do |i|
          expect(results[i]["student uuid"]).to eq @user1.uuid
          expect(results[i]["student name"]).to eq @user1.sortable_name
          expect(results[i]["assignment id"]).to eq @new_quiz.id
          expect(results[i]["assessment title"]).to eq @new_quiz.title
          expect(results[i]["assessment id"]).to eq @new_quiz.id
          expect(results[i]["submission date"]).to eq @new_quiz_submission.submitted_at
          expect(results[i]["submission score"]).to eq @new_quiz_submission&.grade&.to_f
          expect(results[i]["learning outcome name"]).to eq @outcome.short_description
          expect(results[i]["learning outcome id"]).to eq @outcome.id
          expect(results[i]["learning outcome friendly name"]).to eq @outcome.display_name
          expect(results[i]["learning outcome mastered"]).to be false
          expect(results[i]["learning outcome data"]).to eq @outcome.data.to_yaml
          expect(results[i]["learning outcome group title"]).to eq @outcome_group.title
          expect(results[i]["learning outcome group id"]).to eq @outcome_group.id

          # 2 attempts were returned so we are looking at 1st attempt
          expect(results[i]["attempt"]).to eq(2)
          expect(results[i]["learning outcome points hidden"]).to be_nil

          # These equation just make sure we are looking at data from 1st attempt
          expect(results[i]["outcome score"]).to eq i
          expect(results[i]["learning outcome points possible"]).to eq(i + 1)
          expect(results[i]["assessment question id"]).to eq((i + 1).to_s)
          expect(results[i]["assessment question"]).to eq "Attempt 1 Question #{i + 1}"

          expect(results[i]["total percent outcome score"]).to eq 1.0
          expect(results[i]["course name"]).to eq @course1.name
          expect(results[i]["course id"]).to eq @course1.id
          expect(results[i]["course sis id"]).to eq @course1.sis_source_id
          expect(results[i]["assessment type"]).to eq "quiz"
          expect(results[i]["section name"]).to eq @section.name
          expect(results[i]["section id"]).to eq @section.id
          expect(results[i]["section sis id"]).to eq @section.sis_source_id
          expect(results[i]["enrollment state"]).to eq @enrollment1.workflow_state
          expect(results[i]["account id"]).to eq @root_account.id
          expect(results[i]["account name"]).to eq @root_account.name
        end
      end

      it "returns row for each question on latest attempt" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z", [
                                        { id: 1,
                                          authoritative_result_id: 2,
                                          points: 2.0,
                                          points_possible: 2.0,
                                          created_at: "2022-08-19T12:00:00.0Z",
                                          metadata: {
                                            question_metadata: [
                                              {
                                                quiz_item_id: "1",
                                                quiz_item_title: "Attempt 1 Question 1",
                                                points: 0.0,
                                                points_possible: 1.0
                                              },
                                              {
                                                quiz_item_id: "2",
                                                quiz_item_title: "Attempt 1 Question 2",
                                                points: 1.0,
                                                points_possible: 2.0
                                              }
                                            ]
                                          } },
                                        { id: 2,
                                          authoritative_result_id: 2,
                                          points: 2.0,
                                          points_possible: 2.0,
                                          created_at: "2022-08-20T12:00:00.0Z",
                                          metadata: {
                                            question_metadata: [
                                              {
                                                quiz_item_id: "3",
                                                quiz_item_title: "Attempt 2 Question 1",
                                                points: 2.0,
                                                points_possible: 3.0
                                              },
                                              {
                                                quiz_item_id: "4",
                                                quiz_item_title: "Attempt 2 Question 2",
                                                points: 3.0,
                                                points_possible: 4.0
                                              }
                                            ]
                                          } }
                                      ])
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        # We only keep the latest attempt. The latest attempt has 2 questions on it, so we should have 2 results
        expect(results.length).to eq(2)
        results.each_index do |i|
          expect(results[i]["student uuid"]).to eq @user1.uuid
          expect(results[i]["student name"]).to eq @user1.sortable_name
          expect(results[i]["assignment id"]).to eq @new_quiz.id
          expect(results[i]["assessment title"]).to eq @new_quiz.title
          expect(results[i]["assessment id"]).to eq @new_quiz.id
          expect(results[i]["submission date"]).to eq @new_quiz_submission.submitted_at
          expect(results[i]["submission score"]).to eq @new_quiz_submission&.grade&.to_f
          expect(results[i]["learning outcome name"]).to eq @outcome.short_description
          expect(results[i]["learning outcome id"]).to eq @outcome.id
          expect(results[i]["learning outcome friendly name"]).to eq @outcome.display_name
          expect(results[i]["learning outcome mastered"]).to be false
          expect(results[i]["learning outcome data"]).to eq @outcome.data.to_yaml
          expect(results[i]["learning outcome group title"]).to eq @outcome_group.title
          expect(results[i]["learning outcome group id"]).to eq @outcome_group.id

          # 2 attempts were returned so we are looking at 2nd attempt
          expect(results[i]["attempt"]).to eq(2)
          expect(results[i]["learning outcome points hidden"]).to be_nil

          # These equation just make sure we are looking at data from 2nd attempt
          expect(results[i]["outcome score"]).to eq i + 2
          expect(results[i]["learning outcome points possible"]).to eq(i + 3)
          expect(results[i]["assessment question id"]).to eq((i + 3).to_s)
          expect(results[i]["assessment question"]).to eq "Attempt 2 Question #{i + 1}"

          expect(results[i]["total percent outcome score"]).to eq 1.0
          expect(results[i]["course name"]).to eq @course1.name
          expect(results[i]["course id"]).to eq @course1.id
          expect(results[i]["course sis id"]).to eq @course1.sis_source_id
          expect(results[i]["assessment type"]).to eq "quiz"
          expect(results[i]["section name"]).to eq @section.name
          expect(results[i]["section id"]).to eq @section.id
          expect(results[i]["section sis id"]).to eq @section.sis_source_id
          expect(results[i]["enrollment state"]).to eq @enrollment1.workflow_state
          expect(results[i]["account id"]).to eq @root_account.id
          expect(results[i]["account name"]).to eq @root_account.name
        end
      end

      it "returns results for all students" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z")
                       .concat(mock_os_result(@user2, @outcome, @new_quiz, "2022-08-19T12:00:00.0Z"))
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        results = outcome_reports.send(:outcomes_new_quiz_scope)
        expect(results.length).to eq(2)
        expect(results[0]["student uuid"]).to eq @user1.uuid
        expect(results[1]["student uuid"]).to eq @user2.uuid
      end

      it "combines results from both canvas and outcome service" do
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z")
                       .concat(mock_os_result(@user2, @outcome, @new_quiz, "2022-08-19T12:00:00.0Z", [
                                                { id: 1,
                                                  authoritative_result_id: 2,
                                                  points: 2.0,
                                                  points_possible: 2.0,
                                                  metadata: {
                                                    question_metadata: [
                                                      {
                                                        quiz_item_id: "1",
                                                        quiz_item_title: "Attempt 1 Question 1",
                                                        points: 0.0,
                                                        points_possible: 1.0
                                                      },
                                                      {
                                                        quiz_item_id: "2",
                                                        quiz_item_title: "Attempt 1 Question 2",
                                                        points: 2.0,
                                                        points_possible: 2.0
                                                      }
                                                    ]
                                                  } }
                                              ]))
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        outcome_reports.generate
        account_report.reload
        csv = parse_report(account_report, { order: "skip", header: false })

        # Default ordering is by user id, outcome id, course id
        # Results are the following:
        #   - (canvas result) user1, outcome, assignment, score 2 / 3
        #   - (outcome service result) user1, outcome, new quiz, score 5 / 5
        #         this record is 2nd because if user id, outcome id, and course id are equal, we use the canvas result first
        #   - (outcome service result) user2, outcome, new quiz, question 1, score 5 / 5
        #   - (outcome service result) user2, outcome, new quiz, question 2, score 5 / 5
        #   - (canvas result) user2, quiz_outcome, classic quiz, question 1
        #   - (canvas result) user2, quiz_outcome, classic quiz, question 2
        expect(csv.length).to be 6
        expect(csv[0][student_name]).to eq @user1.sortable_name
        expect(csv[0][assessment_title]).to eq @assignment.title
        expect(csv[0][assessment_type]).to eq "assignment"
        expect(csv[0][outcome]).to eq @outcome.short_description
        expect(csv[0][question]).to be_nil
        expect(csv[0][course]).to eq @course1.name
        expect(csv[0][outcome_score]).to eq "2.0"
        expect(csv[0][learning_outcome_points_possible]).to eq @outcome.rubric_criterion[:points_possible].to_s
        expect(csv[0][learning_outcome_mastery_score]).to eq @outcome.rubric_criterion[:mastery_points].to_s
        expect(csv[0][learning_outcome_mastered]).to eq "0"
        expect(csv[0][learning_outcome_rating]).to eq "Lame"
        expect(csv[0][learning_outcome_rating_points]).to eq "0.0" # This is the points associated with the rating

        expect(csv[1][student_name]).to eq @user1.sortable_name
        expect(csv[1][assessment_title]).to eq @new_quiz.title
        expect(csv[1][assessment_type]).to eq "quiz"
        expect(csv[1][outcome]).to eq @outcome.short_description
        expect(csv[1][question]).to be_nil
        expect(csv[1][course]).to eq @course1.name
        expect(csv[1][outcome_score]).to eq "5.0"
        expect(csv[1][learning_outcome_points_possible]).to eq "5.0"
        expect(csv[1][learning_outcome_mastery_score]).to eq @outcome.rubric_criterion[:mastery_points].to_s
        expect(csv[1][learning_outcome_mastered]).to eq "1"
        expect(csv[1][learning_outcome_rating]).to eq "Rockin"
        expect(csv[1][learning_outcome_rating_points]).to eq "3.0" # This is the points associated with the rating

        expect(csv[2][student_name]).to eq @user2.sortable_name
        expect(csv[2][assessment_title]).to eq @new_quiz.title
        expect(csv[2][assessment_type]).to eq "quiz"
        expect(csv[2][outcome]).to eq @outcome.short_description
        expect(csv[2][question]).to eq "Attempt 1 Question 1"
        expect(csv[2][course]).to eq @course1.name
        expect(csv[2][outcome_score]).to eq "0.0"
        expect(csv[2][learning_outcome_points_possible]).to eq "1.0"
        expect(csv[2][learning_outcome_mastery_score]).to eq @outcome.rubric_criterion[:mastery_points].to_s
        expect(csv[2][learning_outcome_mastered]).to eq "0" # 0 / 1 on quiz question
        expect(csv[2][learning_outcome_rating]).to eq "Rockin"
        expect(csv[2][learning_outcome_rating_points]).to eq "3.0"

        expect(csv[3][student_name]).to eq @user2.sortable_name
        expect(csv[3][assessment_title]).to eq @new_quiz.title
        expect(csv[3][assessment_type]).to eq "quiz"
        expect(csv[3][outcome]).to eq @outcome.short_description
        expect(csv[3][question]).to eq "Attempt 1 Question 2"
        expect(csv[3][course]).to eq @course1.name
        expect(csv[3][outcome_score]).to eq "2.0"
        expect(csv[3][learning_outcome_points_possible]).to eq "2.0"
        expect(csv[3][learning_outcome_mastery_score]).to eq @outcome.rubric_criterion[:mastery_points].to_s
        expect(csv[3][learning_outcome_mastered]).to eq "1" # 2 / 2 on quiz question
        expect(csv[3][learning_outcome_rating]).to eq "Rockin"
        expect(csv[3][learning_outcome_rating_points]).to eq "3.0"

        expect(csv[4][student_name]).to eq @user2.sortable_name
        expect(csv[4][assessment_title]).to eq @quiz.title
        expect(csv[4][assessment_type]).to eq "quiz"
        expect(csv[4][outcome]).to eq @quiz_outcome.short_description
        expect(csv[4][question]).to eq @q1.question_data["name"]
        expect(csv[4][question_id]).to eq @q1.assessment_question_id.to_s
        expect(csv[4][course]).to eq @course1.name
        expect(csv[4][outcome_score]).to eq "45.0"
        expect(csv[4][learning_outcome_points_possible]).to eq "45.0"
        expect(csv[4][learning_outcome_mastery_score]).to eq @quiz_outcome.rubric_criterion[:mastery_points].to_s
        expect(csv[4][learning_outcome_mastered]).to eq "1" # 45 / 45 on quiz question
        expect(csv[4][learning_outcome_rating]).to eq "Does Not Meet Expectations"
        expect(csv[4][learning_outcome_rating_points]).to eq "0"

        expect(csv[5][student_name]).to eq @user2.sortable_name
        expect(csv[5][assessment_title]).to eq @quiz.title
        expect(csv[5][assessment_type]).to eq "quiz"
        expect(csv[5][outcome]).to eq @quiz_outcome.short_description
        expect(csv[5][question]).to eq @q2.question_data["name"]
        expect(csv[5][question_id]).to eq @q2.assessment_question_id.to_s
        expect(csv[5][course]).to eq @course1.name
        expect(csv[5][outcome_score]).to eq "0.0"
        expect(csv[5][learning_outcome_points_possible]).to eq "50.0"
        expect(csv[5][learning_outcome_mastery_score]).to eq @quiz_outcome.rubric_criterion[:mastery_points].to_s
        expect(csv[5][learning_outcome_mastered]).to eq "0" # 0 / 50 on quiz question
        expect(csv[5][learning_outcome_rating]).to eq "Does Not Meet Expectations"
        expect(csv[5][learning_outcome_rating_points]).to eq "0"
      end

      it "returns empty report when no results from canvas and OS" do
        LearningOutcomeResult.delete_all
        LearningOutcomeQuestionResult.delete_all
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "off")
        outcome_reports.generate
        account_report.reload
        csv = parse_report(account_report, { order: "skip", header: false })

        expect(csv.length).to eq 1
        expect(csv[0][0]).to eq "No outcomes found"
      end

      it "returns empty report when no results from canvas and empty results from OS" do
        LearningOutcomeResult.delete_all
        LearningOutcomeQuestionResult.delete_all
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return([])

        outcome_reports.generate
        account_report.reload
        csv = parse_report(account_report, { order: "skip", header: false })

        expect(csv.length).to eq 1
        expect(csv[0][0]).to eq "No outcomes found"
      end

      it "returns OS when no canvas results" do
        LearningOutcomeResult.delete_all
        LearningOutcomeQuestionResult.delete_all
        @root_account.set_feature_flag!(:outcome_service_results_to_canvas, "on")

        mock_results = mock_os_result(@user1, @outcome, @new_quiz, "2022-09-19T12:00:00.0Z")
        expect(outcome_reports).to receive(:get_lmgb_results)
          .with(@course1, assignment_ids, "canvas.assignment.quizzes", outcome_ids)
          .and_return(mock_results)

        outcome_reports.generate
        account_report.reload
        csv = parse_report(account_report, { order: "skip", header: false })

        expect(csv.length).to eq 1
        expect(csv[0][student_name]).to eq @user1.sortable_name
        expect(csv[0][assessment_title]).to eq @new_quiz.title
        expect(csv[0][assessment_type]).to eq "quiz"
        expect(csv[0][outcome]).to eq @outcome.short_description
        expect(csv[0][question]).to be_nil
        expect(csv[0][course]).to eq @course1.name
      end
    end

    context "With Account Level Mastery" do
      before(:once) do
        user1_values[:outcome_result]
        @outcome_proficiency = OutcomeProficiency.new(id: 1,
                                                      root_account_id: @root_account.id,
                                                      context_type: "Account",
                                                      context: @root_account,
                                                      outcome_proficiency_ratings: [OutcomeProficiencyRating.new(
                                                        id: 1,
                                                        points: 5,
                                                        color: "3ADF00",
                                                        description: "High Rating",
                                                        mastery: false,
                                                        outcome_proficiency: @outcome_proficiency
                                                      ),
                                                                                    OutcomeProficiencyRating.new(
                                                                                      id: 2,
                                                                                      points: 3,
                                                                                      color: "FFFF00",
                                                                                      description: "Mastery Rating",
                                                                                      mastery: true,
                                                                                      outcome_proficiency: @outcome_proficiency
                                                                                    ),
                                                                                    OutcomeProficiencyRating.new(
                                                                                      id: 3,
                                                                                      points: 1,
                                                                                      color: "FF0000",
                                                                                      description: "Low Rating",
                                                                                      mastery: false,
                                                                                      outcome_proficiency: @outcome_proficiency
                                                                                    )])
        @root_account.outcome_proficiency = @outcome_proficiency
        @root_account.set_feature_flag!(:account_level_mastery_scales, "on")
      end

      it "operates as before when the feature flag is disabled" do
        @root_account.set_feature_flag!(:account_level_mastery_scales, "off")
        expect(report[0]["assessment type"]).to eq "quiz"
        expect(report[0]["learning outcome rating"]).to eq "Does Not Meet Expectations"
        expect(report[0]["learning outcome points possible"]).to eq "45.0"
      end

      it "runs the report and use the outcome proficiencies" do
        report[0]
        expect(report[0]["learning outcome rating"]).to eq "Low Rating"
        expect(report[1]["learning outcome rating"]).to eq "Low Rating"
        expect(report[2]["learning outcome rating"]).to eq "Mastery Rating"
      end

      it "uses the total percent to calculate the rating as opposed to score" do
        @outcome_proficiency.outcome_proficiency_ratings[0].points = 2
        @outcome_proficiency.outcome_proficiency_ratings[1].points = 1
        @outcome_proficiency.outcome_proficiency_ratings[2].points = 0
        @outcome_proficiency.save!
        expect(report[0]["learning outcome rating"]).to eq "Low Rating"
      end

      it "uses the score to create a ratio when calculating rating" do
        @outcome.learning_outcome_results[0].score = 3.0
        @outcome.learning_outcome_results[0].original_score = 3.0
        @outcome.learning_outcome_results[0].percent = 1.0
        @outcome.learning_outcome_results[0].save!
        @outcome_proficiency.outcome_proficiency_ratings[0].points = 50
        @outcome_proficiency.outcome_proficiency_ratings[1].points = 30
        @outcome_proficiency.outcome_proficiency_ratings[2].points = 10
        @outcome_proficiency.save!
        expect(report[0]["learning outcome rating"]).to eq "Low Rating"
        expect(report[1]["learning outcome rating"]).to eq "Low Rating"
        expect(report[2]["learning outcome rating"]).to eq "High Rating"
        expect(report[0]["learning outcome points possible"]).to eq "45.0"
        expect(report[2]["learning outcome points possible"]).to eq "50.0"
      end

      it "has no rating if the score and total_percent are nil" do
        @outcome.learning_outcome_results[0].score = nil
        @outcome.learning_outcome_results[0].original_score = nil
        @outcome.learning_outcome_results[0].percent = nil
        @outcome.learning_outcome_results[0].save!
        expect(report[0]["learning outcome rating"]).to eq "Low Rating"
        expect(report[1]["learning outcome rating"]).to eq "Low Rating"
        expect(report[2]["learning outcome rating"]).to be_nil
      end
    end

    context "With Course Level Mastery" do
      before(:once) do
        @outcome_proficiency = OutcomeProficiency.new(id: 1,
                                                      root_account_id: @root_account.id,
                                                      context_type: "Course",
                                                      context: @course1,
                                                      outcome_proficiency_ratings: [OutcomeProficiencyRating.new(
                                                        id: 1,
                                                        points: 5,
                                                        color: "3ADF00",
                                                        description: "High Rating",
                                                        mastery: false,
                                                        outcome_proficiency: @outcome_proficiency
                                                      ),
                                                                                    OutcomeProficiencyRating.new(
                                                                                      id: 2,
                                                                                      points: 3,
                                                                                      color: "FFFF00",
                                                                                      description: "Mastery Rating",
                                                                                      mastery: true,
                                                                                      outcome_proficiency: @outcome_proficiency
                                                                                    ),
                                                                                    OutcomeProficiencyRating.new(
                                                                                      id: 3,
                                                                                      points: 1,
                                                                                      color: "FF0000",
                                                                                      description: "Low Rating",
                                                                                      mastery: false,
                                                                                      outcome_proficiency: @outcome_proficiency
                                                                                    )])
        @course1.outcome_proficiency = @outcome_proficiency
        @root_account.set_feature_flag!(:account_level_mastery_scales, "on")
      end

      it "runs the report and use the course outcome proficiencies" do
        report[0]
        expect(report[0]["learning outcome rating"]).to eq "Low Rating"
        expect(report[1]["learning outcome rating"]).to eq "Low Rating"
        expect(report[2]["learning outcome rating"]).to eq "Mastery Rating"
        expect(report[0]["learning outcome points possible"]).to eq "45.0"
        expect(report[2]["learning outcome points possible"]).to eq "5.0"
      end
    end
  end
end
