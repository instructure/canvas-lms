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

require_relative "report_spec_helper"

describe "Outcome Reports" do
  include ReportSpecHelper

  let(:user1_rubric_score) { 2 }

  before(:once) do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @root_account = Account.create(name: "New Account", default_time_zone: "UTC")
    @default_term = @root_account.default_enrollment_term
    @course1 = Course.create(name: "English 101", course_code: "ENG101", account: @root_account)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.save!
    @course1.offer!

    @teacher = User.create!
    @course1.enroll_teacher(@teacher)

    @user1 = user_with_managed_pseudonym(
      active_all: true,
      account: @root_account,
      name: "John St. Clair",
      sortable_name: "St. Clair, John",
      username: "john@stclair.com",
      sis_user_id: "user_sis_id_01"
    )
    @user2 = user_with_managed_pseudonym(
      active_all: true,
      username: "micheal@michaelbolton.com",
      name: "Michael Bolton",
      account: @root_account,
      sis_user_id: "user_sis_id_02"
    )

    @enrollment1 = @course1.enroll_user(@user1, "StudentEnrollment", enrollment_state: "active")
    @enrollment2 = @course1.enroll_user(@user2, "StudentEnrollment", enrollment_state: "active")

    @section = @course1.course_sections.first
    assignment_model(course: @course1, title: "English Assignment")
    @outcome_group = @root_account.root_outcome_group
    @outcome = outcome_model(context: @root_account, short_description: "Spelling")
    @rubric = Rubric.create!(context: @course1)
    @rubric.data = [
      {
        points: 3.0,
        description: "Outcome row",
        id: 1,
        ratings: [
          {
            points: 3,
            description: "Rockin'",
            criterion_id: 1,
            id: 2
          },
          {
            points: 0,
            description: "Lame",
            criterion_id: 1,
            id: 3
          }
        ],
        learning_outcome_id: @outcome.id
      }
    ]
    @rubric.instance_variable_set(:@alignments_changed, true)
    @rubric.save!
    @a = @rubric.associate_with(@assignment, @course1, purpose: "grading")
    @assignment.reload
    @submission = @assignment.grade_student(@user1, grade: "10", grader: @teacher).first
    @submission.submission_type = "online_url"
    @submission.submitted_at = 1.week.ago
    @submission.save!
    @outcome.reload
    @outcome_group.add_outcome(@outcome)
    @outcome.reload
    @outcome_group.add_outcome(@outcome)
  end

  before do
    @assessment = @a.assess({
                              user: @user1,
                              assessor: @user2,
                              artifact: @submission,
                              assessment: {
                                assessment_type: "grading",
                                criterion_1: {
                                  points: user1_rubric_score,
                                  comments: "cool, yo"
                                }
                              }
                            })
  end

  def verify_all(report, all_values)
    expect(report.length).to eq all_values.length
    report.each.with_index { |row, i| verify(row, all_values[i], row_index: i) }
  end

  def verify(row, values, row_index: nil)
    user, assignment, outcome, outcome_group, outcome_result, course, section, submission, quiz, question, quiz_outcome_result, quiz_submission, pseudonym =
      values.values_at(:user,
                       :assignment,
                       :outcome,
                       :outcome_group,
                       :outcome_result,
                       :course,
                       :section,
                       :submission,
                       :quiz,
                       :question,
                       :quiz_outcome_result,
                       :quiz_submission,
                       :pseudonym)
    result = quiz.nil? ? outcome_result : quiz_outcome_result
    rating = if outcome.present? && result&.score.present?
               outcome.rubric_criterion&.[](:ratings)&.select do |r|
                 score = if quiz.nil?
                           result.score
                         else
                           result.percent * outcome.points_possible
                         end
                 r[:points].present? && r[:points] <= score
               end&.first
             end
    rating ||= {}

    hide_points = outcome_result&.hide_points
    hide = ->(v) { hide_points ? nil : v }

    expectations = {
      "student name" => user.sortable_name,
      "student id" => user.id,
      "student sis id" => pseudonym&.sis_user_id || user.pseudonym.sis_user_id,
      "assignment title" => assignment&.title,
      "assignment id" => assignment&.id,
      "assignment url" => "https://#{HostUrl.context_host(course)}/courses/#{course.id}/assignments/#{assignment.id}",
      "course id" => course&.id,
      "course name" => course&.name,
      "course sis id" => course&.sis_source_id,
      "section id" => section&.id,
      "section name" => section&.name,
      "section sis id" => section&.sis_source_id,
      "submission date" => quiz_submission&.finished_at&.iso8601 || submission&.submitted_at&.iso8601,
      "submission score" => quiz_submission&.score || submission&.grade&.to_f,
      "learning outcome group title" => outcome_group&.title,
      "learning outcome group id" => outcome_group&.id,
      "learning outcome name" => outcome&.short_description,
      "learning outcome friendly name" => outcome&.display_name,
      "learning outcome id" => outcome&.id,
      "learning outcome mastery score" => hide.call(outcome&.mastery_points),
      "learning outcome points possible" => hide.call(outcome_result&.possible),
      "learning outcome mastered" => unless outcome_result&.mastery.nil?
                                       outcome_result.mastery? ? 1 : 0
                                     end,
      "learning outcome rating" => rating[:description],
      "learning outcome rating points" => hide.call(rating[:points]),
      "attempt" => outcome_result&.attempt,
      "outcome score" => hide.call(outcome_result&.score),
      "account id" => course&.account&.id,
      "account name" => course&.account&.name,
      "assessment title" => quiz&.title || assignment&.title,
      "assessment id" => quiz&.id || assignment&.id,
      "assessment type" => quiz.nil? ? "assignment" : "quiz",
      "assessment question" => question&.name,
      "assessment question id" => question&.id,
      "enrollment state" => user&.enrollments&.find_by(course:, course_section: section)&.workflow_state
    }
    expect(row.headers).to eq row.headers & expectations.keys
    row.headers.each do |key|
      expect(row[key].to_s).to eq(expectations[key].to_s),
                               (row_index.present? ? "for row #{row_index}, " : "") +
                               "for column '#{key}': expected '#{expectations[key]}', received '#{row[key]}'"
    end
  end

  let(:common_values) do
    {
      course: @course1,
      section: @section,
      assignment: @assignment,
      outcome: @outcome,
      outcome_group: @outcome_group
    }
  end
  let(:user1_values) do
    {
      **common_values,
      user: @user1,
      outcome_result: LearningOutcomeResult.find_by(artifact: @assessment),
      submission: @submission
    }
  end
  let(:user2_values) do
    {
      **common_values,
      user: @user2
    }
  end

  let(:report_params) { {} }
  let(:merged_params) { report_params.reverse_merge(order:, parse_header: true, account: @root_account) }
  let(:report) { read_report(report_type, merged_params) }

  shared_examples "common outcomes report behavior" do
    it "runs the report" do
      expect(report[0].headers).to eq expected_headers
    end

    it "has correct values" do
      verify_all(report, all_values)
    end

    it "includes concluded courses" do
      @course1.update! workflow_state: "completed"
      verify_all(report, all_values)
    end

    context "with a term" do
      before do
        @term1 = @root_account.enrollment_terms.create!(
          name: "Fall",
          start_at: 6.months.ago,
          end_at: 1.year.from_now,
          sis_source_id: "fall12"
        )
      end

      let(:report_params) { { params: { "enrollment_term" => @term1.id } } }

      it "filters out courses not in term" do
        expect(report.length).to eq 1
        expect(report[0][0]).to eq "No outcomes found"
      end

      it "includes courses in term" do
        @course1.update! enrollment_term: @term1
        verify_all(report, all_values)
      end
    end

    context "with a sub account" do
      before(:once) do
        @sub_account = Account.create(parent_account: @root_account, name: "English")
      end

      let(:report_params) { { account: @sub_account } }
      let(:common_values) do
        {
          course: @course1,
          section: @section,
          assignment: @assignment,
          outcome: @outcome,
          outcome_group: @sub_account.root_outcome_group
        }
      end

      it "filters courses in a sub account" do
        expect(report.length).to eq 1
        expect(report[0][0]).to eq "No outcomes found"
      end

      it "includes courses in the sub account" do
        @sub_account.root_outcome_group.add_outcome(@outcome)
        @course1.update! account: @sub_account
        verify_all(report, all_values)
      end
    end

    context "with deleted enrollments" do
      before(:once) do
        @enrollment2.destroy!
      end

      it "excludes deleted enrollments by default" do
        remaining_values = all_values.reject { |v| v[:user] == @user2 }
        verify_all(report, remaining_values)
      end

      it "includes deleted enrollments when include_deleted is set" do
        report_record = run_report(report_type, account: @root_account, params: { "include_deleted" => true })
        expect(report_record.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted Objects;"

        report = parse_report(report_record, order:, parse_header: true)
        verify_all(report, all_values)
      end
    end

    it "does not include scores when hidden on learning outcome results" do
      lor = user1_values[:outcome_result]
      lor.update!(hide_points: true)
      verify_all(report, all_values)
    end

    it "does not include invalid learning outcome results" do
      # create result that is invalid because
      # it has an artifact type of submission, instead of
      # a rubric assessment or assessment question
      LearningOutcomeResult.create(
        alignment: ContentTag.create!({
                                        title: "content",
                                        context: @course1,
                                        learning_outcome: @outcopme,
                                        content_id: @assignment.id
                                      }),
        user: @user1,
        artifact: @submission,
        context: @course1,
        possible: @assignment.points_possible,
        score: @submission.score,
        learning_outcome_id: @outcome.id
      )
      verify_all(report, all_values)
    end

    context "with multiple subaccounts" do
      before(:once) do
        @subaccount1 = Account.create! parent_account: @root_account
        @subaccount2 = Account.create! parent_account: @root_account
        @enrollment1 = course_with_student(account: @subaccount1, user: @user1, active_all: true)
        @enrollment2 = course_with_student(account: @subaccount2, user: @user2, active_all: true)
        @rubric1 = outcome_with_rubric(outcome: @outcome, course: @enrollment1.course, outcome_context: @subaccount1)
        @rubric2 = outcome_with_rubric(outcome: @outcome, course: @enrollment2.course, outcome_context: @subaccount2)
        @assessment1 = rubric_assessment_model(context: @enrollment1.course, rubric: @rubric1, user: @user1)
        @assessment2 = rubric_assessment_model(context: @enrollment2.course, rubric: @rubric2, user: @user2)
      end

      let(:user1_subaccount_values) do
        {
          user: @user1,
          course: @enrollment1.course,
          section: @enrollment1.course_section,
          assignment: @assessment1.submission.assignment,
          outcome: @outcome,
          outcome_group: @subaccount1.root_outcome_group,
          outcome_result: LearningOutcomeResult.find_by(artifact: @assessment1),
          submission: @assessment1.submission
        }
      end
      let(:user2_subaccount_values) do
        {
          user: @user2,
          course: @enrollment2.course,
          section: @enrollment2.course_section,
          assignment: @assessment2.submission.assignment,
          outcome: @outcome,
          outcome_group: @subaccount2.root_outcome_group,
          outcome_result: LearningOutcomeResult.find_by(artifact: @assessment2),
          submission: @assessment2.submission
        }
      end

      it "includes results for all subaccounts when run from the root account" do
        values1 = user2_subaccount_values.merge({ outcome_group: @outcome_group })
        values2 = user1_subaccount_values.merge({ outcome_group: @outcome_group })
        combined_values = all_values + [values1, values2]
        combined_values.sort_by! { |v| v[:user].sortable_name }
        verify_all(report, combined_values)
      end

      it "includes only results from subaccount" do
        report = read_report(report_type, account: @subaccount1, parse_header: true)
        verify_all(report, [user1_subaccount_values])
      end
    end

    context "with multiple pseudonyms" do
      it "includes a row for each pseudonym" do
        new_pseudonym = managed_pseudonym(@user1, account: @root_account, sis_user_id: "x_another_id")
        combined_values = all_values + [user1_values.merge(pseudonym: new_pseudonym)]
        combined_values.sort_by! { |v| v[:user].sortable_name }
        verify_all(report, combined_values)
      end
    end

    context "with multiple enrollments" do
      it "includes a single row for enrollments in the same section" do
        multiple_student_enrollment(@user1, @section, course: @course1)
        multiple_student_enrollment(@user1, @section, course: @course1)
        verify_all(report, all_values)
      end

      it "includes multiple rows for enrollments in different sections" do
        section2 = add_section("double your fun", course: @course1)
        multiple_student_enrollment(@user1, section2, course: @course1)
        combined_values = all_values + [user1_values.merge(section: section2)]
        combined_values.sort_by! { |v| [v[:user].sortable_name, v[:section].id] }
        verify_all(report, combined_values)
      end
    end

    context "with mastery and ratings" do
      let(:user1_rubric_score) { 3 }

      it "includes correct mastery and ratings for different scores" do
        user1_row = report.find { |row| row["student name"] == @user1.sortable_name }
        expect(user1_row["learning outcome rating"]).to eq "Rockin"
        expect(user1_row["learning outcome rating points"]).to eq "3.0"
      end
    end
  end

  describe "Student Competency report" do
    let(:report_type) { "student_assignment_outcome_map_csv" }
    let(:expected_headers) { AccountReports::OutcomeReports.student_assignment_outcome_headers }
    let(:all_values) { [user2_values, user1_values] }
    let(:order) { [0, 2, 3, 15] }

    include_examples "common outcomes report behavior"
  end

  describe "outcome results report" do
    let(:report_type) { "outcome_results_csv" }
    let(:expected_headers) { AccountReports::OutcomeReports.outcome_result_headers }
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
        let(:outcome_reports) { AccountReports::OutcomeReports.new(account_report) }
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
          expected_result = nil unless AccountReports::OutcomeReports::ORDER_OPTIONS.include? expected_result
          add_text_calls = expected_result.nil? ? 0 : 1

          expect(outcome_report).to receive(:add_extra_text).exactly(add_text_calls).time
          outcome_report.send(:add_outcome_order_text)

          expect(outcome_report.send(:determine_order_key)).to eq expected_result

          # default ordering is users
          expected_result = "users" if expected_result.nil?
          expect(outcome_report.send(:outcome_order)).to eq AccountReports::OutcomeReports::ORDER_SQL[expected_result]
        end

        it "order key is valid" do
          test_cases = %w[users courses outcomes USERS COURSES OUTCOMES Users usErS foo bar]
          test_cases.each do |test|
            account_report = AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1)
            account_report.parameters = { "order" => test }
            outcome_report = AccountReports::OutcomeReports.new(account_report)
            validate_outcome_ordering(outcome_report, test.downcase)
          end
        end

        it "order key is nil if ordering is not present" do
          account_report = AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1)
          outcome_report = AccountReports::OutcomeReports.new(account_report)
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
          expect(report_record.message).to eq "Outcome Results report successfully generated with the following settings. Account: New Account; Term: All Terms; Include Deleted Objects;"
          expect(report_record.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted Objects;"
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
        let(:outcome_reports) { AccountReports::OutcomeReports.new(account_report) }
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

          outcome_reports.outcome_results
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
          outcome_reports.outcome_results
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

          outcome_reports.outcome_results
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

          outcome_reports.outcome_results
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

  describe "common functionality" do
    let_once(:account_report) { AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1) }
    let_once(:outcome_reports) { AccountReports::OutcomeReports.new(account_report) }

    it "doesn't load courses if account_level_mastery_scales feature is off" do
      outcome_reports.instance_variable_set(:@account_level_mastery_scales_enabled, false)
      row = { "course id" => @course1.id }
      expect(Course).not_to receive(:find)
      outcome_reports.send :add_outcomes_data, row
    end

    it "caches courses" do
      outcome_reports.instance_variable_set(:@account_level_mastery_scales_enabled, true)
      row = { "course id" => @course1.id }
      expect(Course).to receive(:find).with(@course1.id).and_call_original
      outcome_reports.send :add_outcomes_data, row
      expect(Course).not_to receive(:find)
      outcome_reports.send :add_outcomes_data, row
    end

    it "doesn't instantiate the entire scope" do
      scope = outcome_reports.send(:student_assignment_outcome_map_scope)
      expect(scope).not_to receive(:[])
      outcome_reports.send(:write_outcomes_report,
                           AccountReports::OutcomeReports.student_assignment_outcome_headers,
                           scope)
    end
  end
end
