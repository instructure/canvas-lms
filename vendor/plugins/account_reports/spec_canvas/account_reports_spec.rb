#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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

describe "Default Account Reports" do
  before(:each) do
    Notification.find_or_create_by_name("Report Generated")
    Notification.find_or_create_by_name("Report Generation Failed")
    @account = Account.default
    @default_term = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME)
  end

  describe "Student Competency report" do
    before(:each) do
      @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago, :end_at => 1.year.from_now)
      @term1.root_account = @account
      @term1.sis_source_id = 'fall12'
      @term1.save!
      @course = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account)
      @course.save
      @course.sis_source_id = "SIS_COURSE_ID_1"
      @course.save!
      @course.offer!
      @account = Account.default
      @student = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      @student1 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
      @enrollment2 = @course.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')
      assignment_model(:course => @course, :title => 'Engrish Assignment')
      @outcome = @account.created_learning_outcomes.create!(:short_description => 'Spelling')
      @rubric = Rubric.create!(:context => @course)
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
      @a = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
      @assignment.reload
      @submission = @assignment.grade_student(@student, :grade => "10").first
      @submission.submission_type = 'online_url'
      @submission.submitted_at = 1.week.ago
      submission = @submission
      @submission.save!
      @assessment = @a.assess({
                                :user => @student,
                                :assessor => @user,
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

    it "should run the Student Competency report" do

      parsed = ReportSpecHelper.run_report(@account,'student_assignment_outcome_map_csv',{},1)
      parsed.length.should == 2

      parsed[0][0].should == @student.sortable_name
      parsed[0][1].should == @student.id.to_s
      parsed[0][2].should == "user_sis_id_01"
      parsed[0][3].should == @assignment.title
      parsed[0][4].should == @assignment.id.to_s
      parsed[0][5].should == @submission.submitted_at.iso8601
      parsed[0][6].should == @submission.grade.to_s
      parsed[0][7].should == @outcome.short_description
      parsed[0][8].should == @outcome.id.to_s
      parsed[0][9].should == '1'
      parsed[0][10].should == '2'
      parsed[0][11].should == @course.name
      parsed[0][12].should == @course.id.to_s
      parsed[0][13].should == @course.sis_course_id
      parsed[0][14].should == "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"

      parsed[1][0].should == @student1.sortable_name
      parsed[1][1].should == @student1.id.to_s
      parsed[1][2].should == nil
      parsed[1][3].should == @assignment.title
      parsed[1][4].should == @assignment.id.to_s
      parsed[1][5].should == nil
      parsed[1][6].should == nil
      parsed[1][7].should == @outcome.short_description
      parsed[1][8].should == @outcome.id.to_s
      parsed[1][9].should == nil
      parsed[1][10].should == nil
      parsed[1][11].should == @course.name
      parsed[1][12].should == @course.id.to_s
      parsed[1][13].should == @course.sis_course_id
      parsed[1][14].should == "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"

    end

    it "should run the Student Competency report on a term" do

      parameters = {}
      parameters["enrollment_term"] = @term1.id
      parsed = ReportSpecHelper.run_report(@account,'student_assignment_outcome_map_csv',parameters)
      parsed.length.should == 1
      parsed[0].should == ["No outcomes found"]

    end

    it "should run the Student Competency report on a sub account" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')

      parameters = {}
      parsed = ReportSpecHelper.run_report(sub_account,'student_assignment_outcome_map_csv',parameters)
      parsed.length.should == 1
      parsed[0].should == ["No outcomes found"]

    end

    it "should run the Student Competency report on a sub account with courses" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      @course.account = sub_account
      @course.save!
      @outcome.context_id = sub_account.id
      @outcome.save!

      param = {}
      parsed = ReportSpecHelper.run_report(sub_account,'student_assignment_outcome_map_csv',param,1)
      parsed.length.should == 2
      parsed[0].should == [@student.sortable_name, @student.id.to_s, "user_sis_id_01", @assignment.title, @assignment.id.to_s,
                           @submission.submitted_at.iso8601, @submission.grade.to_s, @outcome.short_description,
                           @outcome.id.to_s, '1', '2', @course.name, @course.id.to_s, @course.sis_course_id,
                           "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"]

      parsed[1].should == [@student1.sortable_name, @student1.id.to_s, nil, @assignment.title, @assignment.id.to_s, nil, nil,
                           @outcome.short_description, @outcome.id.to_s, nil, nil, @course.name, @course.id.to_s, @course.sis_course_id,
                           "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"]

    end

    it "should run the Student Competency report with deleted enrollments" do
      @enrollment2.destroy

      param = {}
      param["include_deleted"] = true
      parsed = ReportSpecHelper.run_report(@account,'student_assignment_outcome_map_csv',param,1)
      parsed.length.should == 2

      parsed[0].should == [@student.sortable_name, @student.id.to_s, "user_sis_id_01", @assignment.title, @assignment.id.to_s,
                           @submission.submitted_at.iso8601, @submission.grade.to_s, @outcome.short_description,
                           @outcome.id.to_s, '1', '2', @course.name, @course.id.to_s, @course.sis_course_id,
                           "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"]

      parsed[1].should == [@student1.sortable_name, @student1.id.to_s, nil, @assignment.title, @assignment.id.to_s, nil, nil,
                           @outcome.short_description, @outcome.id.to_s, nil, nil, @course.name, @course.id.to_s, @course.sis_course_id,
                           "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"]

    end
  end

  # The report should get all the grades for the term provided
  # create 2 courses each with students
  # have a student in both courses
  # have sis id's and not sis ids
  describe "Grade Export report" do
    before(:each) do
      @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago, :end_at => 1.year.from_now)
      @term1.root_account = @account
      @term1.sis_source_id = 'fall12'
      @term1.save!
      @user1 = user_with_managed_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair",
                                           :sortable_name => "St. Clair, John", :username => 'john@stclair.com',
                                           :sis_user_id => "user_sis_id_01")
      @user2 = user_with_managed_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com',
                                           :name => 'Michael Bolton', :account => @account,
                                           :sis_user_id => "user_sis_id_02")
      @user3 = user_with_managed_pseudonym(:active_all => true, :account => @account, :name => "Rick Astley",
                                           :sortable_name => "Astley, Rick", :username => 'rick@roll.com',
                                           :sis_user_id => "user_sis_id_03")
      @user4 = user_with_managed_pseudonym(:active_all => true, :username => 'jason@donovan.com',
                                           :name => 'Jason Donovan', :account => @account,
                                           :sis_user_id => "user_sis_id_04")
      @user5 = user_with_managed_pseudonym(:active_all => true,:username => 'john@smith.com',
                                           :name => 'John Smith', :sis_user_id => "user_sis_id_05",
                                           :account => @account)

      @course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account)
      @course1.workflow_state = 'available'
      @course1.enrollment_term_id = @term1.id
      @course1.sis_source_id = "SIS_COURSE_ID_1"
      @course1.save!
      @course2 = course(:course_name => 'Math 101', :account => @account, :active_course => true)
      @enrollment1 = @course1.enroll_user(@user1, 'StudentEnrollment', :enrollment_state => :active)
      @enrollment1.computed_final_score = 88
      @enrollment1.save!
      @enrollment2 = @course1.enroll_user(@user2, 'StudentEnrollment', :enrollment_state => :active)
      @enrollment2.computed_final_score = 90
      @enrollment2.save!
      @enrollment3 = @course2.enroll_user(@user2, 'StudentEnrollment', :enrollment_state => :active)
      @enrollment3.computed_final_score = 93
      @enrollment3.save!
      @enrollment4 = @course1.enroll_user(@user3, 'StudentEnrollment', :enrollment_state => :active)
      @enrollment4.computed_final_score = 97
      @enrollment4.save!
      @enrollment5 = @course2.enroll_user(@user4, 'StudentEnrollment', :enrollment_state => :active)
      @enrollment5.computed_final_score = 99
      @enrollment5.save!
      @enrollment6 = @course1.enroll_user(@user5,'TeacherEnrollment',:enrollment_state => :active)
      @enrollment7 = @course2.enroll_user(@user5,'TaEnrollment',:enrollment_state => :active)
    end

    it "should run grade export for a term" do

      parameters = {}
      parameters["enrollment_term"] = @term1.id
      parsed = ReportSpecHelper.run_report(@account,'grade_export_csv',parameters,13)
      parsed.length.should == 3

      parsed[0].should == ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88"]
      parsed[1].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90"]
      parsed[2].should == ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97"]
    end

    it "should run grade export for a term using sis_id" do

      parameters = {}
      parameters["enrollment_term"] = "sis_term_id:fall12"
      parsed = ReportSpecHelper.run_report(@account,'grade_export_csv',parameters,13)

      parsed[0].should == ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88"]
      parsed[1].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90"]
      parsed[2].should == ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97"]
    end

    it "should run grade export with no parameters" do

      parsed = ReportSpecHelper.run_report(@account,'grade_export_csv',{},13)
      parsed.length.should == 5

      parsed[0].should == ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88"]
      parsed[1].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90"]
      parsed[2].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93"]
      parsed[3].should == ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97"]
      parsed[4].should == ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99"]
    end

    it "should run grade export with empty string parameter" do

      parameters = {}
      parameters["enrollment_term"] = ""
      parsed = ReportSpecHelper.run_report(@account,'grade_export_csv',parameters,13)
      parsed.length.should == 5

      parsed[0].should == ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88"]
      parsed[1].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90"]
      parsed[2].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93"]
      parsed[3].should == ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97"]
      parsed[4].should == ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99"]
    end

    it "should run grade export with deleted users" do

      @course2.destroy
      @enrollment1.destroy

      parameters = {}
      parameters["include_deleted"] = true
      parsed = ReportSpecHelper.run_report(@account,'grade_export_csv',parameters,13)
      parsed.length.should == 5

      parsed[0].should == ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88"]
      parsed[1].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90"]
      parsed[2].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93"]
      parsed[3].should == ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97"]
      parsed[4].should == ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99"]
    end

    it "should run grade export on a sub account" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      @course2.account = sub_account
      @course2.save!

      parameters = {}
      parsed = ReportSpecHelper.run_report(sub_account,'grade_export_csv',parameters,13)
      parsed.length.should == 2

      parsed[0].should == ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93"]
      parsed[1].should == ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99"]
    end
  end

  it "should find the default module and configured reports" do
    ReportSpecHelper.find_account_module_and_reports('default')
  end
end
