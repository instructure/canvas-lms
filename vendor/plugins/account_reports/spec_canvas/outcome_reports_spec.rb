#
# Copyright (C) 2013 Instructure, Inc.
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

describe "Outcom Reports" do
  before(:each) do
    Notification.find_or_create_by_name("Report Generated")
    Notification.find_or_create_by_name("Report Generation Failed")
    @account = Account.default
    @default_term = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME)
    @course1 = Course.create(:name => 'English 101', :course_code => 'ENG101', :account => @account)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.save!
    @course1.offer!
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
    @submission = @assignment.grade_student(@user1, :grade => "10").first
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

  end

  describe "Student Competency report" do
    before(:each) do
      @type = 'student_assignment_outcome_map_csv'
    end

    it "should run the Student Competency report" do

      parsed = ReportSpecHelper.run_report(@account, @type, {}, 1)
      parsed.length.should == 2

      parsed[0][0].should == @user1.sortable_name
      parsed[0][1].should == @user1.id.to_s
      parsed[0][2].should == "user_sis_id_01"
      parsed[0][3].should == @assignment.title
      parsed[0][4].should == @assignment.id.to_s
      parsed[0][5].should == @submission.submitted_at.iso8601
      parsed[0][6].should == @submission.grade.to_s
      parsed[0][7].should == @outcome.short_description
      parsed[0][8].should == @outcome.id.to_s
      parsed[0][9].should == '1'
      parsed[0][10].should == '2'
      parsed[0][11].should == @course1.name
      parsed[0][12].should == @course1.id.to_s
      parsed[0][13].should == @course1.sis_source_id
      parsed[0][14].should == @section.name
      parsed[0][15].should == @section.id.to_s
      parsed[0][16].should == @section.sis_source_id
      parsed[0][17].should == "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"

      parsed[1][0].should == @user2.sortable_name
      parsed[1][1].should == @user2.id.to_s
      parsed[1][2].should == "user_sis_id_02"
      parsed[1][3].should == @assignment.title
      parsed[1][4].should == @assignment.id.to_s
      parsed[1][5].should == nil
      parsed[1][6].should == nil
      parsed[1][7].should == @outcome.short_description
      parsed[1][8].should == @outcome.id.to_s
      parsed[1][9].should == nil
      parsed[1][10].should == nil
      parsed[1][11].should == @course1.name
      parsed[1][12].should == @course1.id.to_s
      parsed[1][13].should == @course1.sis_source_id
      parsed[1][14].should == @section.name
      parsed[1][15].should == @section.id.to_s
      parsed[1][16].should == @section.sis_source_id
      parsed[1][17].should == "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"

    end

    it "should run the Student Competency report on a term" do
      @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago, :end_at => 1.year.from_now)
      @term1.root_account = @account
      @term1.sis_source_id = 'fall12'
      @term1.save!

      parameters = {}
      parameters["enrollment_term"] = @term1.id
      parsed = ReportSpecHelper.run_report(@account, @type, parameters)
      parsed.length.should == 1
      parsed[0].should == ["No outcomes found"]

    end

    it "should run the Student Competency report on a sub account" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')

      parameters = {}
      parsed = ReportSpecHelper.run_report(sub_account, @type, parameters)
      parsed.length.should == 1
      parsed[0].should == ["No outcomes found"]

    end

    it "should run the Student Competency report on a sub account with courses" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      @course1.account = sub_account
      @course1.save!
      @outcome.context_id = sub_account.id
      @outcome.save!

      param = {}
      parsed = ReportSpecHelper.run_report(sub_account, @type, param, 1)
      parsed.length.should == 2
      parsed[0].should == [@user1.sortable_name, @user1.id.to_s, "user_sis_id_01",
                           @assignment.title, @assignment.id.to_s,
                           @submission.submitted_at.iso8601, @submission.grade.to_s,
                           @outcome.short_description, @outcome.id.to_s, '1', '2',
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]

      parsed[1].should == [@user2.sortable_name, @user2.id.to_s, "user_sis_id_02",
                           @assignment.title, @assignment.id.to_s, nil, nil,
                           @outcome.short_description, @outcome.id.to_s, nil, nil,
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]

    end

    it "should run the Student Competency report with deleted enrollments" do
      @enrollment2.destroy

      param = {}
      param["include_deleted"] = true
      parsed = ReportSpecHelper.run_report(@account, @type, param, 1)
      parsed.length.should == 2

      parsed[0].should == [@user1.sortable_name, @user1.id.to_s, "user_sis_id_01",
                           @assignment.title, @assignment.id.to_s,
                           @submission.submitted_at.iso8601, @submission.grade.to_s,
                           @outcome.short_description, @outcome.id.to_s, '1', '2',
                           @course1.name, @course1.id.to_s,@course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]

      parsed[1].should == [@user2.sortable_name, @user2.id.to_s, "user_sis_id_02",
                           @assignment.title, @assignment.id.to_s, nil, nil,
                           @outcome.short_description, @outcome.id.to_s, nil, nil,
                           @course1.name, @course1.id.to_s, @course1.sis_source_id,
                           @section.name, @section.id.to_s, @section.sis_source_id,
                           "https://#{HostUrl.context_host(@course1)}/courses/#{@course1.id}/assignments/#{@assignment.id}"]

    end
  end

  describe "outcome results report" do
    before(:each) do
      @type = 'outcome_results_csv'
    end

    it "should run the outcome result report" do
      parsed = ReportSpecHelper.run_report(@account, @type, {}, 1)

      parsed.length.should == 1
      parsed[0][0].should == @user1.sortable_name
      parsed[0][1].should == @user1.id.to_s
      parsed[0][2].should == "user_sis_id_01"
      parsed[0][3].should == @assignment.title
      parsed[0][4].should == @assignment.id.to_s
      parsed[0][5].should == 'assignment'
      parsed[0][6].should == @submission.submitted_at.iso8601
      parsed[0][7].should == @submission.grade.to_s
      parsed[0][8].should == @outcome.short_description
      parsed[0][9].should == @outcome.id.to_s
      parsed[0][10].should == '1'
      parsed[0][11].should == '2'
      parsed[0][12].should == nil
      parsed[0][13].should == nil
      parsed[0][14].should == @course1.name
      parsed[0][15].should == @course1.id.to_s
      parsed[0][16].should == @course1.sis_source_id
    end

    it "should work with quizzes" do
      outcome = @account.created_learning_outcomes.create!(:short_description => 'new outcome')
      quiz = @course1.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      q1 = quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'}, 'answer_3' => {'answer_text' => '4'}}})
      q2 = quiz.quiz_questions.create!(:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'}, 'answer_3' => {'answer_text' => '4'}}})
      bank = q1.assessment_question.assessment_question_bank
      bank.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
      outcome.align(bank, @account, :mastery_score => 0.7)
      answer_1 = q1.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      answer_2 = q2.question_data[:answers].detect { |a| a[:weight] == 100 }[:id]
      quiz.generate_quiz_data(:persist => true)
      sub = quiz.generate_submission(@user)
      sub.submission_data = {}
      question_1 = q1.question_data[:id]
      question_2 = q2.question_data[:id]
      sub.submission_data["question_#{question_1}"] = answer_1
      sub.submission_data["question_#{question_2}"] = answer_2 + 1
      sub.grade_submission
      outcome.reload

      parsed = ReportSpecHelper.run_report(@account, @type, {}, [1,13])
      parsed.length.should == 3

      parsed[0][0].should == @user1.sortable_name
      parsed[0][1].should == @user1.id.to_s
      parsed[0][2].should == "user_sis_id_01"
      parsed[0][3].should == @assignment.title
      parsed[0][4].should == @assignment.id.to_s
      parsed[0][5].should == 'assignment'
      parsed[0][6].should == @submission.submitted_at.iso8601
      parsed[0][7].should == @submission.grade.to_s
      parsed[0][8].should == @outcome.short_description
      parsed[0][9].should == @outcome.id.to_s
      parsed[0][10].should == '1'
      parsed[0][11].should == '2'
      parsed[0][12].should == nil
      parsed[0][13].should == nil
      parsed[0][14].should == @course1.name
      parsed[0][15].should == @course1.id.to_s
      parsed[0][16].should == @course1.sis_source_id

      parsed[1][0].should == @user2.sortable_name
      parsed[1][1].should == @user2.id.to_s
      parsed[1][2].should == "user_sis_id_02"
      parsed[1][3].should == quiz.title
      parsed[1][4].should == quiz.id.to_s
      parsed[1][5].should == 'quiz'
      parsed[1][6].should == sub.finished_at.iso8601
      parsed[1][7].should == sub.score.to_s
      parsed[1][8].should == outcome.short_description
      parsed[1][9].should == outcome.id.to_s
      parsed[1][10].should == '1'
      parsed[1][11].should == '1'
      parsed[1][12].should == 'question 1'
      parsed[1][13].should == q1.assessment_question.id.to_s
      parsed[1][14].should == @course1.name
      parsed[1][15].should == @course1.id.to_s
      parsed[1][16].should == @course1.sis_source_id

      parsed[2][0].should == @user2.sortable_name
      parsed[2][1].should == @user2.id.to_s
      parsed[2][2].should == "user_sis_id_02"
      parsed[2][3].should == quiz.title
      parsed[2][4].should == quiz.id.to_s
      parsed[2][5].should == 'quiz'
      parsed[2][6].should == sub.finished_at.iso8601
      parsed[2][7].should == sub.score.to_s
      parsed[2][8].should == outcome.short_description
      parsed[2][9].should == outcome.id.to_s
      parsed[2][10].should == '1'
      parsed[2][11].should == '0'
      parsed[2][12].should == 'question 2'
      parsed[2][13].should == q2.assessment_question.id.to_s
      parsed[2][14].should == @course1.name
      parsed[2][15].should == @course1.id.to_s
      parsed[2][16].should == @course1.sis_source_id

    end
  end
end