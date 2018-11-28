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

require File.expand_path(File.dirname(__FILE__) + '/report_spec_helper')

describe "Outcome Reports" do
  include ReportSpecHelper

  let(:user1_rubric_score) { 2 }

  before(:once) do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @root_account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @default_term = @root_account.default_enrollment_term
    @course1 = Course.create(:name => 'English 101', :course_code => 'ENG101', :account => @root_account)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.save!
    @course1.offer!

    @teacher = User.create!
    @course1.enroll_teacher(@teacher)

    @user1 = user_with_managed_pseudonym(
      :active_all => true, :account => @root_account, :name => 'John St. Clair',
      :sortable_name => 'St. Clair, John', :username => 'john@stclair.com',
      :sis_user_id => 'user_sis_id_01'
    )
    @user2 = user_with_managed_pseudonym(
      :active_all => true, :username => 'micheal@michaelbolton.com',
      :name => 'Michael Bolton', :account => @root_account,
      :sis_user_id => 'user_sis_id_02'
    )

    @course1.enroll_user(@user1, "StudentEnrollment", :enrollment_state => 'active')
    @enrollment2 = @course1.enroll_user(@user2, "StudentEnrollment", :enrollment_state => 'active')

    @section = @course1.course_sections.first
    assignment_model(:course => @course1, :title => 'Engrish Assignment')
    outcome_group = @root_account.root_outcome_group
    @outcome = outcome_model(context: @root_account, :short_description => 'Spelling')
    @rubric = Rubric.create!(:context => @course1)
    @rubric.data = [
      {
        :points => 3.0,
        :description => "Outcome row",
        :id => 1,
        :ratings => [
          {
            :points => 3,
            :description => "Rockin'",
            :criterion_id => 1,
            :id => 2
          },
          {
            :points => 0,
            :description => "Lame",
            :criterion_id => 1,
            :id => 3
          }
        ],
        :learning_outcome_id => @outcome.id
      }
    ]
    @rubric.instance_variable_set('@alignments_changed', true)
    @rubric.save!
    @a = @rubric.associate_with(@assignment, @course1, :purpose => 'grading')
    @assignment.reload
    @submission = @assignment.grade_student(@user1, grade: "10", grader: @teacher).first
    @submission.submission_type = 'online_url'
    @submission.submitted_at = 1.week.ago
    @submission.save!
    @outcome.reload
    outcome_group.add_outcome(@outcome)
    @outcome.reload
    outcome_group.add_outcome(@outcome)
  end

  before do
    @assessment = @a.assess({
                              :user => @user1,
                              :assessor => @user2,
                              :artifact => @submission,
                              :assessment => {
                                :assessment_type => 'grading',
                                :criterion_1 => {
                                  :points => user1_rubric_score,
                                  :comments => "cool, yo"
                                }
                              }
                            })
  end

  def verify_all(report, all_values)
    expect(report.length).to eq all_values.length
    report.each.with_index { |row, i| verify(row, all_values[i], row_index: i) }
  end

  def verify(row, values, row_index: nil)
    user, assignment, outcome, outcome_result, course, section, submission, quiz, question, quiz_outcome_result, quiz_submission, pseudonym =
      values.values_at(:user, :assignment, :outcome, :outcome_result, :course, :section, :submission, :quiz, :question,
      :quiz_outcome_result, :quiz_submission, :pseudonym)
    result = quiz.nil? ? outcome_result : quiz_outcome_result
    rating = if outcome.present? && result&.score&.present?
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
    hide = lambda { |v| hide_points ? nil : v }

    expectations = {
      'student name' => user.sortable_name,
      'student id' => user.id,
      'student sis id' => pseudonym&.sis_user_id || user.pseudonym.sis_user_id,
      'assignment title' => assignment&.title,
      'assignment id' => assignment&.id,
      'assignment url' => "https://#{HostUrl.context_host(course)}/courses/#{course.id}/assignments/#{assignment.id}",
      'course id' => course&.id,
      'course name' => course&.name,
      'course sis id' => course&.sis_source_id,
      'section id' => section&.id,
      'section name' => section&.name,
      'section sis id' => section&.sis_source_id,
      'submission date' => quiz_submission&.finished_at&.iso8601 || submission&.submitted_at&.iso8601,
      'submission score' => quiz_submission&.score || submission&.grade&.to_f,
      'learning outcome name' => outcome&.short_description,
      'learning outcome friendly name' => outcome&.display_name,
      'learning outcome id' => outcome&.id,
      'learning outcome mastery score' => hide.call(outcome&.mastery_points),
      'learning outcome points possible' => hide.call(outcome_result&.possible),
      'learning outcome mastered' => unless outcome_result&.mastery.nil?
                                       outcome_result.mastery? ? 1 : 0
                                     end,
      'learning outcome rating' => rating[:description],
      'learning outcome rating points' => hide.call(rating[:points]),
      'attempt' => outcome_result&.attempt,
      'outcome score' => hide.call(outcome_result&.score),
      'account id' => course&.account&.id,
      'account name' => course&.account&.name,
      "assessment title" => quiz&.title || assignment&.title,
      "assessment id" => quiz&.id || assignment&.id,
      "assessment type" => quiz.nil? ? 'assignment' : 'quiz',
      "assessment question" => question&.name,
      "assessment question id" => question&.id,
      "enrollment state" => user&.enrollments&.find_by(course: course, course_section: section)&.workflow_state
    }
    expect(row.headers).to eq row.headers & expectations.keys

    row.headers.each do |key|
      expect(row[key].to_s).to eq(expectations[key].to_s),
        (row_index.present? ? "for row #{row_index}, " : '') +
        "for column '#{key}': expected '#{expectations[key]}', received '#{row[key]}'"
    end
  end

  let(:common_values) do
    {
      course: @course1,
      section: @section,
      assignment: @assignment,
      outcome: @outcome
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
  let(:merged_params) { report_params.reverse_merge(order: order, parse_header: true, account: @root_account) }
  let(:report) { read_report(report_type, merged_params) }

  shared_examples 'common outcomes report behavior' do
    it "should run the report" do
      expect(report[0].headers).to eq expected_headers
    end

    it 'has correct values' do
      verify_all(report, all_values)
    end

    context 'with a term' do
      before do
        @term1 = @root_account.enrollment_terms.create!(
          name: 'Fall',
          start_at: 6.months.ago,
          end_at: 1.year.from_now,
          sis_source_id: 'fall12'
        )
      end
      let(:report_params) { { params: { 'enrollment_term' => @term1.id } } }

      it "should filter out courses not in term" do
        expect(report.length).to eq 1
        expect(report[0][0]).to eq "No outcomes found"
      end

      it 'should include courses in term' do
        @course1.update! enrollment_term: @term1
        verify_all(report, all_values)
      end
    end

    context 'with a sub account' do
      before(:once) do
        @sub_account = Account.create(:parent_account => @root_account, :name => 'English')
      end
      let(:report_params) { { account: @sub_account } }

      it "should filter courses in a sub account" do
        expect(report.length).to eq 1
        expect(report[0][0]).to eq "No outcomes found"
      end

      it "should include courses in the sub account" do
        @sub_account.root_outcome_group.add_outcome(@outcome)
        @course1.update! account: @sub_account
        verify_all(report, all_values)
      end
    end

    context 'with deleted enrollments' do
      before(:once) do
        @enrollment2.destroy!
      end

      it 'should exclude deleted enrollments by default' do
        remaining_values = all_values.reject { |v| v[:user] == @user2 }
        verify_all(report, remaining_values)
      end

      it 'should include deleted enrollments when include_deleted is set' do
        report_record = run_report(report_type, account: @root_account, params: { 'include_deleted' => true })
        expect(report_record.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted Objects;"

        report = parse_report(report_record, order: order, parse_header: true)
        verify_all(report, all_values)
      end
    end

    it "should not include scores when hidden on learning outcome results" do
      lor = user1_values[:outcome_result]
      lor.update!(hide_points: true)
      verify_all(report, all_values)
    end

    it "should not include invalid learning outcome results" do
      # create result that is invalid because
      # it has an artifact type of submission, instead of
      # a rubric assessment or assessment question
      ct = @assignment.learning_outcome_alignments.last
      lor = ct.learning_outcome_results.for_association(@assignment).build
      lor.user = @user1
      lor.artifact = @submission
      lor.context = ct.context
      lor.possible = @assignment.points_possible
      lor.score = @submission.score
      lor.save!
      verify_all(report, all_values)
    end

    context 'with multiple subaccounts' do
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
          outcome_result: LearningOutcomeResult.find_by(artifact: @assessment2),
          submission: @assessment2.submission
        }
      end

      it 'includes results for all subaccounts when run from the root account' do
        combined_values = all_values + [user1_subaccount_values, user2_subaccount_values]
        combined_values.sort_by! { |v| v[:user].sortable_name }

        verify_all(report, combined_values)
      end

      it 'includes only results from subaccount' do
        report = read_report(report_type, account: @subaccount1, parse_header: true)
        verify_all(report, [user1_subaccount_values])
      end
    end

    context 'with multiple pseudonyms' do
      it 'includes a row for each pseudonym' do
        new_pseudonym = managed_pseudonym(@user1, account: @root_account, sis_user_id: 'x_another_id')
        combined_values = all_values + [user1_values.merge(pseudonym: new_pseudonym)]
        combined_values.sort_by! { |v| v[:user].sortable_name }
        verify_all(report, combined_values)
      end
    end

    context 'with multiple enrollments' do
      it 'includes a single row for enrollments in the same section' do
        multiple_student_enrollment(@user1, @section, course: @course1)
        multiple_student_enrollment(@user1, @section, course: @course1)
        verify_all(report, all_values)
      end

      it 'includes multiple rows for enrollments in different sections' do
        section2 = add_section('double your fun', course: @course1)
        multiple_student_enrollment(@user1, section2, course: @course1)
        combined_values = all_values + [user1_values.merge(section: section2)]
        combined_values.sort_by! { |v| [v[:user].sortable_name, v[:section].id] }
        verify_all(report, combined_values)
      end
    end

    context 'with mastery and ratings' do
      let(:user1_rubric_score) { 3 }

      it 'includes correct mastery and ratings for different scores' do
        user1_row = report.select { |row| row['student name'] == @user1.sortable_name }.first
        expect(user1_row['learning outcome rating']).to eq 'Rockin'
        expect(user1_row['learning outcome rating points']).to eq '3.0'
      end
    end
  end

  describe "Student Competency report" do
    let(:report_type) { 'student_assignment_outcome_map_csv' }
    let(:expected_headers) { AccountReports::OutcomeReports.student_assignment_outcome_headers.keys }
    let(:all_values) { [user2_values, user1_values] }
    let(:order) { [0, 2, 3, 15] }

    include_examples 'common outcomes report behavior'
  end

  describe "outcome results report" do
    let(:report_type) { 'outcome_results_csv' }
    let(:expected_headers) { AccountReports::OutcomeReports.outcome_result_headers.keys }
    let(:all_values) { [user1_values] }
    let(:order) { [0, 2, 3, 13, 18] }

    include_examples 'common outcomes report behavior'

    context 'with quiz question results' do
      before(:once) do
        outcome_group = @root_account.root_outcome_group
        @quiz_outcome = @root_account.created_learning_outcomes.create!(:short_description => 'new outcome')
        @quiz = @course1.quizzes.create!(:title => "new quiz", :shuffle_answers => true, quiz_type: 'assignment')
        @q1 = @quiz.quiz_questions.create!(:question_data => true_false_question_data)
        @q2 = @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)
        bank = @q1.assessment_question.assessment_question_bank
        bank.assessment_questions.create!(:question_data => true_false_question_data)
        @quiz_outcome.align(bank, @root_account, :mastery_score => 0.7)
        answer_1 = @q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
        answer_2 = @q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
        @quiz.generate_quiz_data(:persist => true)
        @quiz_submission = @quiz.generate_submission(@user)
        @quiz_submission.submission_data = {}
        @quiz_submission.submission_data["question_#{@q1.id}"] = answer_1
        @quiz_submission.submission_data["question_#{@q2.id}"] = answer_2 + 1
        Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
        @quiz_outcome.reload
        outcome_group.add_outcome(@quiz_outcome)
        @quiz_outcome_result = LearningOutcomeResult.find_by(artifact: @quiz_submission)
      end

      it "should work with quizzes" do
        common_quiz_values = {
          user: @user2,
          quiz: @quiz,
          quiz_submission: @quiz_submission,
          outcome: @quiz_outcome,
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

      it 'should include ratings for quiz questions' do
        expect(report[0]['assessment type']).to eq 'quiz'
        expect(report[0]['learning outcome rating']).to eq 'Does Not Meet Expectations'
      end
    end
  end
end
