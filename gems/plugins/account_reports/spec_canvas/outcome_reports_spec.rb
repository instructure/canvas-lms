#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

  before(:once) do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @default_term = @account.default_enrollment_term
    @course1 = Course.create(:name => 'English 101', :course_code => 'ENG101', :account => @account)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.save!
    @course1.offer!

    @teacher = User.create!
    @course1.enroll_teacher(@teacher)

    @user1 = user_with_managed_pseudonym(
      :active_all => true, :account => @account, :name => 'John St. Clair',
      :sortable_name => 'St. Clair, John', :username => 'john@stclair.com',
      :sis_user_id => 'user_sis_id_01')
    @user2 = user_with_managed_pseudonym(
      :active_all => true, :username => 'micheal@michaelbolton.com',
      :name => 'Michael Bolton', :account => @account,
      :sis_user_id => 'user_sis_id_02')

    @course1.enroll_user(@user1, "StudentEnrollment", :enrollment_state => 'active')
    @enrollment2 = @course1.enroll_user(@user2, "StudentEnrollment", :enrollment_state => 'active')

    @section = @course1.course_sections.first
    assignment_model(:course => @course1, :title => 'Engrish Assignment')
    outcome_group = @account.root_outcome_group
    @outcome = @account.created_learning_outcomes.create!(:short_description => 'Spelling')
    @rubric = Rubric.create!(:context => @course1)
    @rubric.data = [
      {
        :points => 3,
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
    @assessment = @a.assess({
                              :user => @user1,
                              :assessor => @user2,
                              :artifact => @submission,
                              :assessment => {
                                :assessment_type => 'grading',
                                :criterion_1 => {
                                  :points => 2,
                                  :comments => "cool, yo"
                                }
                              }
                            })
    @outcome.reload
    outcome_group.add_outcome(@outcome)

  end

  describe "Student Competency report" do
    before(:each) do
      @type = 'student_assignment_outcome_map_csv'
    end

    it "should run the Student Competency report" do

      parsed = read_report(@type, {order: [0, 1]})

      expect(parsed[0][0]).to eq @user2.sortable_name
      expect(parsed[0][1]).to eq @user2.id.to_s
      expect(parsed[0][2]).to eq "user_sis_id_02"
      expect(parsed[0][3]).to eq @assignment.title
      expect(parsed[0][4]).to eq @assignment.id.to_s
      expect(parsed[0][5]).to eq nil
      expect(parsed[0][6]).to eq nil
      expect(parsed[0][7]).to eq @outcome.short_description
      expect(parsed[0][8]).to eq @outcome.id.to_s
      expect(parsed[0][9]).to eq nil
      expect(parsed[0][10]).to eq nil
      expect(parsed[0][11]).to eq @course1.name
      expect(parsed[0][12]).to eq @course1.id.to_s
      expect(parsed[0][13]).to eq @course1.sis_source_id
      expect(parsed[0][14]).to eq @section.name
      expect(parsed[0][15]).to eq @section.id.to_s
      expect(parsed[0][16]).to eq @section.sis_source_id
      expect(parsed[0][17]).to eq "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"

      expect(parsed[1][0]).to eq @user1.sortable_name
      expect(parsed[1][1]).to eq @user1.id.to_s
      expect(parsed[1][2]).to eq "user_sis_id_01"
      expect(parsed[1][3]).to eq @assignment.title
      expect(parsed[1][4]).to eq @assignment.id.to_s
      expect(parsed[1][5]).to eq @submission.submitted_at.iso8601
      expect(parsed[1][6]).to eq @submission.grade.to_f.to_s
      expect(parsed[1][7]).to eq @outcome.short_description
      expect(parsed[1][8]).to eq @outcome.id.to_s
      expect(parsed[1][9]).to eq '1'
      expect(parsed[1][10]).to eq '2.0'
      expect(parsed[1][11]).to eq @course1.name
      expect(parsed[1][12]).to eq @course1.id.to_s
      expect(parsed[1][13]).to eq @course1.sis_source_id
      expect(parsed[1][14]).to eq @section.name
      expect(parsed[1][15]).to eq @section.id.to_s
      expect(parsed[1][16]).to eq @section.sis_source_id
      expect(parsed[1][17]).to eq "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"

      expect(parsed.length).to eq 2

    end

    it "should run the Student Competency report on a term" do
      @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago, :end_at => 1.year.from_now)
      @term1.root_account = @account
      @term1.sis_source_id = 'fall12'
      @term1.save!

      parameters = {}
      parameters["enrollment_term"] = @term1.id
      parsed = read_report(@type, {params: parameters})
      expect(parsed[0]).to eq ["No outcomes found"]
      expect(parsed.length).to eq 1

    end

    it "should run the Student Competency report on a sub account" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')

      parameters = {}
      parsed = read_report(@type, {params: parameters, account: sub_account})
      expect(parsed[0]).to eq ["No outcomes found"]
      expect(parsed.length).to eq 1

    end

    it "should run the Student Competency report on a sub account with courses" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      outcome_group = sub_account.root_outcome_group
      @course1.account = sub_account
      @course1.save!
      @outcome.context_id = sub_account.id
      @outcome.save!
      outcome_group.add_outcome(@outcome)

      parsed = read_report(@type, {order: [0, 1], account: sub_account})
      expect(parsed[1]).to eq [@user1.sortable_name, @user1.id.to_s, "user_sis_id_01",
                           @assignment.title, @assignment.id.to_s,
                           @submission.submitted_at.iso8601, @submission.grade.to_f.to_s,
                           @outcome.short_description, @outcome.id.to_s, '1', '2.0',
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]

      expect(parsed[0]).to eq [@user2.sortable_name, @user2.id.to_s, "user_sis_id_02",
                           @assignment.title, @assignment.id.to_s, nil, nil,
                           @outcome.short_description, @outcome.id.to_s, nil, nil,
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]
      expect(parsed.length).to eq 2

    end

    it "should run the Student Competency report with deleted enrollments" do
      @enrollment2.destroy

      param = {}
      param["include_deleted"] = true
      report = run_report(@type, {params: param})
      expect(report.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted Objects;"
      parsed = parse_report(report, {order: 0})

      expect(parsed[1]).to eq [@user1.sortable_name, @user1.id.to_s, "user_sis_id_01",
                           @assignment.title, @assignment.id.to_s,
                           @submission.submitted_at.iso8601, @submission.grade.to_f.to_s,
                           @outcome.short_description, @outcome.id.to_s, '1', '2.0',
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]

      expect(parsed[0]).to eq [@user2.sortable_name, @user2.id.to_s, "user_sis_id_02",
                           @assignment.title, @assignment.id.to_s, nil, nil,
                           @outcome.short_description, @outcome.id.to_s, nil, nil,
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]
      expect(parsed.length).to eq 2

    end

    it "should not incluce invalid learning outcome results" do
      ct = @assignment.learning_outcome_alignments.last
      lor = ct.learning_outcome_results.for_association(@assignment).build
      lor.user = @user1
      lor.artifact = @submission
      lor.context = ct.context
      lor.possible = @assignment.points_possible
      lor.score = @submission.score
      lor.save!

      parsed = read_report(@type, {order: 0})
      expect(parsed.length).to eq 2
    end
  end

  describe "outcome results report" do
    before(:each) do
      @type = 'outcome_results_csv'
    end

    it "should run the outcome result report" do
      parsed = read_report(@type)

      expect(parsed[0][0]).to eq @user1.sortable_name
      expect(parsed[0][1]).to eq @user1.id.to_s
      expect(parsed[0][2]).to eq "user_sis_id_01"
      expect(parsed[0][3]).to eq @assignment.title
      expect(parsed[0][4]).to eq @assignment.id.to_s
      expect(parsed[0][5]).to eq 'assignment'
      expect(parsed[0][6]).to eq @submission.submitted_at.iso8601
      expect(parsed[0][7]).to eq @submission.grade.to_f.to_s
      expect(parsed[0][8]).to eq @outcome.short_description
      expect(parsed[0][9]).to eq @outcome.id.to_s
      expect(parsed[0][10]).to eq '1'
      expect(parsed[0][11]).to eq '2.0'
      expect(parsed[0][12]).to eq nil
      expect(parsed[0][13]).to eq nil
      expect(parsed[0][14]).to eq @course1.name
      expect(parsed[0][15]).to eq @course1.id.to_s
      expect(parsed[0][16]).to eq @course1.sis_source_id
      expect(parsed.length).to eq 1
    end

    it "should work with quizzes" do
      outcome_group = @account.root_outcome_group
      outcome = @account.created_learning_outcomes.create!(:short_description => 'new outcome')
      quiz = @course1.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      q1 = quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '1', 'weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]})
      q2 = quiz.quiz_questions.create!(:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '1', 'weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]})
      bank = q1.assessment_question.assessment_question_bank
      bank.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
      outcome.align(bank, @account, :mastery_score => 0.7)
      answer_1 = q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      answer_2 = q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      quiz.generate_quiz_data(:persist => true)
      sub = quiz.generate_submission(@user)
      sub.submission_data = {}
      question_1 = q1[:id]
      question_2 = q2[:id]
      sub.submission_data["question_#{question_1}"] = answer_1
      sub.submission_data["question_#{question_2}"] = answer_2 + 1
      Quizzes::SubmissionGrader.new(sub).grade_submission
      outcome.reload
      outcome_group.add_outcome(outcome)

      parsed = read_report(@type, {order: [0, 13]})

      expect(parsed[2][0]).to eq @user1.sortable_name
      expect(parsed[2][1]).to eq @user1.id.to_s
      expect(parsed[2][2]).to eq "user_sis_id_01"
      expect(parsed[2][3]).to eq @assignment.title
      expect(parsed[2][4]).to eq @assignment.id.to_s
      expect(parsed[2][5]).to eq 'assignment'
      expect(parsed[2][6]).to eq @submission.submitted_at.iso8601
      expect(parsed[2][7]).to eq @submission.grade.to_f.to_s
      expect(parsed[2][8]).to eq @outcome.short_description
      expect(parsed[2][9]).to eq @outcome.id.to_s
      expect(parsed[2][10]).to eq '1'
      expect(parsed[2][11]).to eq '2.0'
      expect(parsed[2][12]).to eq nil
      expect(parsed[2][13]).to eq nil
      expect(parsed[2][14]).to eq @course1.name
      expect(parsed[2][15]).to eq @course1.id.to_s
      expect(parsed[2][16]).to eq @course1.sis_source_id

      expect(parsed[0][0]).to eq @user2.sortable_name
      expect(parsed[0][1]).to eq @user2.id.to_s
      expect(parsed[0][2]).to eq "user_sis_id_02"
      expect(parsed[0][3]).to eq quiz.title
      expect(parsed[0][4]).to eq quiz.id.to_s
      expect(parsed[0][5]).to eq 'quiz'
      expect(parsed[0][6]).to eq sub.finished_at.iso8601
      expect(parsed[0][7]).to eq sub.score.to_s
      expect(parsed[0][8]).to eq outcome.short_description
      expect(parsed[0][9]).to eq outcome.id.to_s
      expect(parsed[0][10]).to eq '1'
      expect(parsed[0][11]).to eq '1.0'
      expect(parsed[0][12]).to eq 'question 1'
      expect(parsed[0][13]).to eq q1.assessment_question.id.to_s
      expect(parsed[0][14]).to eq @course1.name
      expect(parsed[0][15]).to eq @course1.id.to_s
      expect(parsed[0][16]).to eq @course1.sis_source_id

      expect(parsed[1][0]).to eq @user2.sortable_name
      expect(parsed[1][1]).to eq @user2.id.to_s
      expect(parsed[1][2]).to eq "user_sis_id_02"
      expect(parsed[1][3]).to eq quiz.title
      expect(parsed[1][4]).to eq quiz.id.to_s
      expect(parsed[1][5]).to eq 'quiz'
      expect(parsed[1][6]).to eq sub.finished_at.iso8601
      expect(parsed[1][7]).to eq sub.score.to_s
      expect(parsed[1][8]).to eq outcome.short_description
      expect(parsed[1][9]).to eq outcome.id.to_s
      expect(parsed[1][10]).to eq '1'
      expect(parsed[1][11]).to eq '0.0'
      expect(parsed[1][12]).to eq 'question 2'
      expect(parsed[1][13]).to eq q2.assessment_question.id.to_s
      expect(parsed[1][14]).to eq @course1.name
      expect(parsed[1][15]).to eq @course1.id.to_s
      expect(parsed[1][16]).to eq @course1.sis_source_id

      expect(parsed.length).to eq 3

      # NOTE: remove after data migration of polymorphic relationships having: Quiz
      result = LearningOutcomeResult.where(association_type: 'Quizzes::Quiz').first
      result.association_type = 'Quiz'
      result.send(:save_without_callbacks)

      parsed = read_report(@type, {order: [0, 13]})
      expect(parsed[2][5]).to eq 'assignment'
      expect(parsed[0][5]).to eq 'quiz'
      expect(parsed[1][5]).to eq 'quiz'

      # NOTE: remove after data migration of polymorphic relationships having: QuizSubmission
      result = LearningOutcomeResult.where(artifact_type: 'Quizzes::QuizSubmission').first
      LearningOutcomeResult.where(id: result).update_all(association_type: 'QuizSubmission')

      parsed = read_report(@type, {order: [0, 13]})
      expect(parsed[0][6]).to eq sub.finished_at.iso8601
      expect(parsed[0][7]).to eq sub.score.to_f.to_s
      expect(parsed[1][6]).to eq sub.finished_at.iso8601
      expect(parsed[1][7]).to eq sub.score.to_f.to_s
    end

    it 'should include in extra text if option is set' do
      param = {}
      param["include_deleted"] = true
      report = run_report(@type, {params: param})
      expect(report.parameters["extra_text"]).to eq "Term: All Terms; Include Deleted Objects;"
    end
  end
end
