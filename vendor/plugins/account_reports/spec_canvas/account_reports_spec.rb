#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/reports_helper')

describe "Default Account Reports" do

  it "should run the Student Competency report" do
    Notification.find_or_create_by_name("Report Generated")
    Notification.find_or_create_by_name("Report Generation Failed")

    @account = Account.default
    student_in_course(:course => @course, :active_all => true, :name => 'Luke Skywalker')
    @student1 = User.create(:name => 'Bilbo Baggins')
    @course.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')
    assignment_model(:course => @course, :title => 'Engrish Assignment')
    @outcome = @account.learning_outcomes.create!(:short_description => 'Spelling')
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
    @rubric.instance_variable_set('@outcomes_changed', true)
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

    account_report = AccountReport.new(:user=>@admin, :account=>@account, :report_type=>'student_assignment_outcome_map_csv')
    account_report.save
    csv_report = Canvas::AccountReports::Default.student_assignment_outcome_map_csv(account_report)
    all_parsed = FasterCSV.parse(csv_report).to_a
    parsed = all_parsed[1..-1].sort_by { |r| r[1] }

    parsed[0][0].should == @student.sortable_name
    parsed[0][1].should == @student.id.to_s
    parsed[0][2].should == @assignment.title
    parsed[0][3].should == @assignment.id.to_s
    parsed[0][4].should == @submission.submitted_at.iso8601
    parsed[0][5].should == @submission.grade.to_s
    parsed[0][6].should == @outcome.short_description
    parsed[0][7].should == @outcome.id.to_s
    parsed[0][8].should == '1'
    parsed[0][9].should == '2'
    parsed[0][10].should == @course.name
    parsed[0][11].should == @course.id.to_s
    parsed[0][12].should == "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"

    parsed[1][0].should == @student1.sortable_name
    parsed[1][1].should == @student1.id.to_s
    parsed[1][2].should == @assignment.title
    parsed[1][3].should == @assignment.id.to_s
    parsed[1][4].should == nil
    parsed[1][5].should == nil
    parsed[1][6].should == @outcome.short_description
    parsed[1][7].should == @outcome.id.to_s
    parsed[1][8].should == nil
    parsed[1][9].should == nil
    parsed[1][10].should == @course.name
    parsed[1][11].should == @course.id.to_s
    parsed[1][12].should == "https://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/#{@assignment.id}"

  end

  # The report should get all the grades for the term provided
  # create 2 courses each with students
  # have a student in both courses
  # have sis id's and not sis ids

  it "should run grade export"do
    Notification.find_or_create_by_name("Report Generated")
    Notification.find_or_create_by_name("Report Generation Failed")
    @account = Account.default
    student_in_course(:course => @course, :active_all => true, :name => 'Luke Skywalker')
    course1 = @course
    course1.sis_source_id = "SISr2d2"
    course1.name = 'robotics 101'
    course1.save
    student0 = @student
    @pseudonym = pseudonym(@student)
    #this user should be second in the report
    student0.pseudonym.sis_user_id = 'xwing001'
    student0.pseudonym.save!
    @student1 = User.create(:name => 'Bilbo Baggins')
    @pseudonym = pseudonym(@student1, :username => 'bilbo@example.com')
    # this user should be first in the report
    @student1.pseudonym.sis_user_id = 'shire111'
    @student1.pseudonym.save!
    course1.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')
    assignment_model(:course => course1, :title => 'Engrish Assignment')
    @assignment.reload
    @submission = @assignment.grade_student(student0, :grade => "1.46").first
    @submission.save!
    #create a concluded enrollment in the first course that should not show up
    @student2 = User.create(:name => 'dead guy')
    @pseudonym2 = pseudonym(@student2, :username => 'concluded@example.com')
    @student2.pseudonym.sis_user_id = 'qwertyui23'
    @student2.pseudonym.save!
    course1.enroll_user(@student2, "StudentEnrollment", :enrollment_state => 'invited')

    #this user should be last in the report because no sis id
    course_with_teacher(:account => @account, :active_all => true, :course_name => "course1")
    course2 = @course
    course2.sis_source_id = "haha"
    course2.save
    student_in_course(:course => course2, :active_all => true)
    # student0 should have two courses, rows 2 and 3
    course2.enroll_user(student0, "StudentEnrollment", :enrollment_state => 'active')

    account_report = AccountReport.new(:user=>@admin, :account=>@account, :report_type=>'grade_export_csv')
    account_report.parameters = {}
    account_report.parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
    account_report.save!
    csv_report = Canvas::AccountReports::Default.grade_export_csv(account_report)
    all_parsed = FasterCSV.parse(csv_report).to_a
    #remove header
    parsed = all_parsed[1..-1]

    parsed[0][0].should == student0.name
    parsed[0][1].should == student0.id.to_s
    parsed[0][2].should == student0.sis_user_id.to_s
    parsed[0][3].should == course1.name
    parsed[0][4].should == course1.id.to_s
    parsed[0][5].should == course1.sis_source_id.to_s
    course_section = course1.course_sections.first
    parsed[0][6].should == course_section.name
    parsed[0][7].should == course_section.id.to_s
    parsed[0][8].to_s.should == course_section.sis_source_id.to_s
    parsed[0][9].should == course1.enrollment_term.name
    parsed[0][10].should == course1.enrollment_term.id.to_s
    parsed[0][11].to_s.should == course1.enrollment_term.sis_source_id.to_s
    course1grade = student0.enrollments.find_by_course_id(course1.id)
    parsed[0][12].to_s.should == course1grade.computed_current_score.to_s
    parsed[0][13].to_s.should == course1grade.computed_final_score.to_s

    parsed[1][0].should == @student1.name
    parsed[1][1].should == @student1.id.to_s
    parsed[1][2].should == @student1.sis_user_id.to_s
    parsed[1][3].should == course1.name
    parsed[1][4].should == course1.id.to_s
    parsed[1][5].should == course1.sis_source_id.to_s
    parsed[1][6].should == @student1.enrollments.first.course_section.name
    parsed[1][7].should == @student1.enrollments.first.course_section.id.to_s
    parsed[1][8].to_s.should == @student1.enrollments.first.course_section.sis_source_id.to_s
    parsed[1][9].should == course1.enrollment_term.name
    parsed[1][10].should == course1.enrollment_term.id.to_s
    parsed[1][11].to_s.should == course1.enrollment_term.sis_source_id.to_s
    parsed[1][12].to_s.should == @student1.enrollments.first.computed_current_score.to_s
    parsed[1][13].to_s.should == @student1.enrollments.first.computed_final_score.to_s

    parsed[2][0].should == @student.name
    parsed[2][1].should == @student.id.to_s
    parsed[2][2].to_s.should == @student.sis_user_id.to_s
    parsed[2][3].should == course2.name
    parsed[2][4].should == course2.id.to_s
    parsed[2][5].should == course2.sis_source_id.to_s
    parsed[2][6].should == @student.enrollments.last.course_section.name
    parsed[2][7].should == @student.enrollments.last.course_section.id.to_s
    parsed[2][8].to_s.should == @student.enrollments.last.course_section.sis_source_id.to_s
    parsed[2][9].should == course2.enrollment_term.name
    parsed[2][10].should == course2.enrollment_term.id.to_s
    parsed[2][11].to_s.should == course2.enrollment_term.sis_source_id.to_s
    parsed[2][12].to_s.should == @student.enrollments.last.computed_current_score.to_s
    parsed[2][13].to_s.should == @student.enrollments.last.computed_final_score.to_s

    parsed[3][0].should == student0.name
    parsed[3][1].should == student0.id.to_s
    parsed[3][2].should == student0.sis_user_id.to_s
    parsed[3][3].should == course2.name
    parsed[3][4].should == course2.id.to_s
    parsed[3][5].should == course2.sis_source_id.to_s
    parsed[3][6].should == course2.course_sections.first.name
    parsed[3][7].should == course2.course_sections.first.id.to_s
    parsed[3][8].to_s.should == course2.course_sections.first.sis_source_id.to_s
    parsed[3][9].should == course2.enrollment_term.name
    parsed[3][10].should == course2.enrollment_term.id.to_s
    parsed[3][11].to_s.should == course2.enrollment_term.sis_source_id.to_s
    course2grade = student0.enrollments.find_by_course_id(course2.id)
    parsed[3][12].to_s.should == course2grade.computed_current_score.to_s
    parsed[3][13].to_s.should == course2grade.computed_final_score.to_s

  end

  # The report should get all the grades for the all terms
  # create 2 courses each with students
  # have a student in both courses
  # have sis id's and not sis ids

  it "should run grade export for all terms"do
    Notification.find_or_create_by_name("Report Generated")
    Notification.find_or_create_by_name("Report Generation Failed")
    @account = Account.default
    student_in_course(:course => @course, :active_all => true, :name => 'Luke Skywalker')
    course1 = @course
    course1.sis_source_id = "SISr2d2"
    course1.name = 'robotics 101'
    course1.save
    student0 = @student
    @pseudonym = pseudonym(@student)
    #this user should be second in the report
    student0.pseudonym.sis_user_id = 'xwing001'
    student0.pseudonym.save!
    @student1 = User.create(:name => 'Bilbo Baggins')
    @pseudonym = pseudonym(@student1, :username => 'bilbo@example.com')
    # this user should be first in the report
    @student1.pseudonym.sis_user_id = 'shire111'
    @student1.pseudonym.save!
    course1.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')
    assignment_model(:course => course1, :title => 'Engrish Assignment')
    @assignment.reload
    @submission = @assignment.grade_student(student0, :grade => "1.46").first
    @submission.save!
    #create a concluded enrollment in the first course that should not show up
    @student2 = User.create(:name => 'dead guy')
    @pseudonym2 = pseudonym(@student2, :username => 'concluded@example.com')
    @student2.pseudonym.sis_user_id = 'qwertyui23'
    @student2.pseudonym.save!
    course1.enroll_user(@student2, "StudentEnrollment", :enrollment_state => 'deleted')

    #this user should be last in the report because no sis id
    course_with_teacher(:account => @account, :active_all => true, :course_name => "course1")
    course2 = @course
    course2.sis_source_id = "haha"
    course2.save
    student_in_course(:course => course2, :active_all => true)
    # student0 should have two courses, rows 2 and 3
    course2.enroll_user(student0, "StudentEnrollment", :enrollment_state => 'active')

    account_report = AccountReport.new(:user=>@admin, :account=>@account, :report_type=>'grade_export_csv')
    account_report.parameters = {}
    account_report.save!
    csv_report = Canvas::AccountReports::Default.grade_export_csv(account_report)
    all_parsed = FasterCSV.parse(csv_report).to_a
    #remove header
    parsed = all_parsed[1..-1]

    parsed[0][0].should == student0.name
    parsed[0][1].should == student0.id.to_s
    parsed[0][2].should == student0.sis_user_id.to_s
    parsed[0][3].should == course1.name
    parsed[0][4].should == course1.id.to_s
    parsed[0][5].should == course1.sis_source_id.to_s
    course_section = course1.course_sections.first
    parsed[0][6].should == course_section.name
    parsed[0][7].should == course_section.id.to_s
    parsed[0][8].to_s.should == course_section.sis_source_id.to_s
    parsed[0][9].should == course1.enrollment_term.name
    parsed[0][10].should == course1.enrollment_term.id.to_s
    parsed[0][11].to_s.should == course1.enrollment_term.sis_source_id.to_s
    course1grade = student0.enrollments.find_by_course_id(course1.id)
    parsed[0][12].to_s.should == course1grade.computed_current_score.to_s
    parsed[0][13].to_s.should == course1grade.computed_final_score.to_s

    parsed[1][0].should == @student1.name
    parsed[1][1].should == @student1.id.to_s
    parsed[1][2].should == @student1.sis_user_id.to_s
    parsed[1][3].should == course1.name
    parsed[1][4].should == course1.id.to_s
    parsed[1][5].should == course1.sis_source_id.to_s
    parsed[1][6].should == @student1.enrollments.first.course_section.name
    parsed[1][7].should == @student1.enrollments.first.course_section.id.to_s
    parsed[1][8].to_s.should == @student1.enrollments.first.course_section.sis_source_id.to_s
    parsed[1][9].should == course1.enrollment_term.name
    parsed[1][10].should == course1.enrollment_term.id.to_s
    parsed[1][11].to_s.should == course1.enrollment_term.sis_source_id.to_s
    parsed[1][12].to_s.should == @student1.enrollments.first.computed_current_score.to_s
    parsed[1][13].to_s.should == @student1.enrollments.first.computed_final_score.to_s

    parsed[2][0].should == @student.name
    parsed[2][1].should == @student.id.to_s
    parsed[2][2].to_s.should == @student.sis_user_id.to_s
    parsed[2][3].should == course2.name
    parsed[2][4].should == course2.id.to_s
    parsed[2][5].should == course2.sis_source_id.to_s
    parsed[2][6].should == @student.enrollments.last.course_section.name
    parsed[2][7].should == @student.enrollments.last.course_section.id.to_s
    parsed[2][8].to_s.should == @student.enrollments.last.course_section.sis_source_id.to_s
    parsed[2][9].should == course2.enrollment_term.name
    parsed[2][10].should == course2.enrollment_term.id.to_s
    parsed[2][11].to_s.should == course2.enrollment_term.sis_source_id.to_s
    parsed[2][12].to_s.should == @student.enrollments.last.computed_current_score.to_s
    parsed[2][13].to_s.should == @student.enrollments.last.computed_final_score.to_s

    parsed[3][0].should == student0.name
    parsed[3][1].should == student0.id.to_s
    parsed[3][2].should == student0.sis_user_id.to_s
    parsed[3][3].should == course2.name
    parsed[3][4].should == course2.id.to_s
    parsed[3][5].should == course2.sis_source_id.to_s
    parsed[3][6].should == course2.course_sections.first.name
    parsed[3][7].should == course2.course_sections.first.id.to_s
    parsed[3][8].to_s.should == course2.course_sections.first.sis_source_id.to_s
    parsed[3][9].should == course2.enrollment_term.name
    parsed[3][10].should == course2.enrollment_term.id.to_s
    parsed[3][11].to_s.should == course2.enrollment_term.sis_source_id.to_s
    course2grade = student0.enrollments.find_by_course_id(course2.id)
    parsed[3][12].to_s.should == course2grade.computed_current_score.to_s
    parsed[3][13].to_s.should == course2grade.computed_final_score.to_s

  end

  def run_report(parameters = {}, column = 0)

    account_report = AccountReport.new(:user => @admin, :account => @account, :report_type => "sis_export_csv")
    account_report.parameters = {}
    account_report.parameters = parameters
    account_report.save
    csv_report = Canvas::AccountReports::Default.sis_export_csv(account_report)
    if csv_report.is_a? Hash
      csv_report.inject({}) do |result, (key, csv)|
        all_parsed = FasterCSV.parse(csv).to_a
        all_parsed[1..-1].sort_by { |r| r[column] }
        result[key] = all_parsed
        result
      end
    else
      all_parsed = FasterCSV.parse(csv_report).to_a
      all_parsed[1..-1].sort_by { |r| r[column] }
    end
  end

  describe "SIS export reports" do

    it "should run the SIS Users" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      @admin = account_admin_user(:account => @account)
      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:name => 'Rick Astley', :account => @account)
      #user3 has no sis_id and should not be in the report

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["users"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2

      parsed[0][0].should == user1.pseudonym.sis_user_id
      parsed[0][1].should == user1.pseudonym.login
      parsed[0][2].should == nil
      parsed[0][3].should == "John St."
      parsed[0][4].should == "Clair"
      parsed[0][5].should == "john@stclair.com"
      parsed[0][6].should == "active"

      parsed[1][0].should == user2.pseudonym.sis_user_id
      parsed[1][1].should == user2.pseudonym.login
      parsed[1][2].should == nil
      parsed[1][3].should == "Michael"
      parsed[1][4].should == "Bolton"
      parsed[1][5].should == "micheal@michaelbolton.com"
      parsed[1][6].should == "active"

      parameters = {}
      parameters["users"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2

      parsed[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      parsed[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]
    end

    it "should run the SIS Accounts" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!
      sub_sub_account = Account.create(:parent_account => sub_account, :name => 'ESL')
      sub_sub_account.sis_source_id = 'subsub1'
      sub_sub_account.save!
      sub_account2 = Account.create(:parent_account => @account, :name => 'Math')
      sub_account2.sis_source_id = 'sub2'
      sub_account2.save!
      sub_account3 = Account.create(:parent_account => @account, :name => 'other')
      #sub_account 3 does not have sis id and should not be in the report
      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["accounts"] = true
      parsed = run_report(parameters)
      parsed.length.should == 3

      parsed[0][0].should == sub_account.sis_source_id
      parsed[0][1].should == nil
      parsed[0][2].should == "English"
      parsed[0][3].should == "active"

      parsed[1][0].should == sub_account2.sis_source_id
      parsed[1][1].should == nil
      parsed[1][2].should == "Math"
      parsed[1][3].should == "active"

      parsed[2][0].should == sub_sub_account.sis_source_id
      parsed[2][1].should == sub_account.sis_source_id
      parsed[2][2].should == "ESL"
      parsed[2][3].should == "active"

      parameters = {}
      parameters["accounts"] = true
      parsed = run_report(parameters)
      parsed.length.should == 3
      parsed[0].should == ["sub1", nil, "English", "active"]
      parsed[1].should == ["sub2", nil, "Math", "active"]
      parsed[2].should == ["subsub1", "sub1", "ESL", "active"]
    end

    it "should run the SIS Terms" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!
      term2 = EnrollmentTerm.create(:name => 'Winter', :start_at => '07-01-2013', :end_at => '28-04-2013')
      term2.root_account = @account
      term2.sis_source_id = 'winter13'
      term2.save!
      #default term should not be included in the report since it does not have an sis id
      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["terms"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2

      parsed[0][0].should == term1.sis_source_id
      parsed[0][1].should == term1.name
      parsed[0][2].should == "active"
      parsed[0][3].should == term1.start_at.iso8601
      parsed[0][4].should == term1.end_at.iso8601

      parsed[1][0].should == term2.sis_source_id
      parsed[1][1].should == term2.name
      parsed[1][2].should == "active"
      parsed[1][3].should == term2.start_at.iso8601
      parsed[1][4].should == term2.end_at.iso8601

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["terms"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == ["fall12", "Fall", "active", "2012-08-20T00:00:00Z", "2012-12-20T00:00:00Z"]
      parsed[1].should == ["winter13", "Winter", "active", "2013-01-07T00:00:00Z", "2013-04-28T00:00:00Z"]
    end

    it "should run the SIS Courses" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!

      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!

      start_at = 1.day.ago
      end_at = 10.days.from_now

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account, :enrollment_term => term1)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.restrict_enrollments_to_course_dates = true
      course1.save!

      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :conclude_at => end_at, :account => @account)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.restrict_enrollments_to_course_dates = true
      course2.save!

      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save
      course3.sis_source_id = "SIS_COURSE_ID_3"
      course3.save!

      course4 = Course.new(:name => 'self help')
      #course4 should not show up since it does not have sis id

      course5 = Course.new(:name => 'math 100', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account, :enrollment_term => term1)
      course5.workflow_state = 'completed'
      course5.save!
      #course5 should not show up since it is not active
      parameters = {}
      parameters["courses"] = true
      parsed = run_report(parameters)
      parsed.length.should == 3

      parsed[0][0].should == course1.sis_source_id
      parsed[0][1].should == course1.course_code
      parsed[0][2].should == course1.name
      parsed[0][3].should == sub_account.sis_source_id
      parsed[0][4].should == term1.sis_source_id
      parsed[0][5].should == "active"
      parsed[0][6].should == start_at.iso8601
      parsed[0][7].should == end_at.iso8601

      parsed[1][0].should == course2.sis_source_id
      parsed[1][1].should == course2.course_code
      parsed[1][2].should == course2.name
      parsed[1][3].should == nil
      parsed[1][4].should == nil
      parsed[1][5].should == "active"
      parsed[1][6].should == nil
      parsed[1][7].should == end_at.iso8601

      parsed[2][0].should == course3.sis_source_id
      parsed[2][1].should == course3.course_code
      parsed[2][2].should == course3.name
      parsed[2][3].should == nil
      parsed[2][4].should == nil
      parsed[2][5].should == "active"
      parsed[2][6].should == nil
      parsed[2][7].should == nil

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["courses"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      parsed[1].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]
    end

    it "should run the SIS Sections" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!

      start_at = 1.day.ago
      end_at = 10.days.from_now

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.save!

      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :conclude_at => end_at, :account => @account, :enrollment_term => term1)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.save!

      section1 = CourseSection.new(:name => 'English_01', :course => course1, :account => sub_account, :start_at => start_at, :end_at => end_at)
      section1.sis_source_id = 'english_section_1'
      section1.root_account_id = @account.id
      section1.restrict_enrollments_to_section_dates = true
      section1.save!

      section2 = CourseSection.new(:name => 'English_02', :course => course1, :end_at => end_at)
      section2.sis_source_id = 'english_section_2'
      section2.root_account_id = @account.id
      section2.restrict_enrollments_to_section_dates = true
      section2.save!

      section3 = CourseSection.new(:name => 'Math_01', :course => course2, :end_at => end_at)
      section3.sis_source_id = 'english_section_3'
      section3.root_account_id = @account.id
      section3.restrict_enrollments_to_section_dates = true
      section3.save!

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["sections"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2

      parsed[0][0].should == section1.sis_source_id
      parsed[0][1].should == course1.sis_source_id
      parsed[0][2].should == section1.name
      parsed[0][3].should == "active"
      parsed[0][4].should == start_at.iso8601
      parsed[0][5].should == end_at.iso8601
      parsed[0][6].should == sub_account.sis_source_id

      parsed[1][0].should == section2.sis_source_id
      parsed[1][1].should == course1.sis_source_id
      parsed[1][2].should == section2.name
      parsed[1][3].should == "active"
      parsed[1][4].should == nil
      parsed[1][5].should == end_at.iso8601
      parsed[1][6].should == nil

      parameters = {}
      parameters["sections"] = true
      parsed = run_report(parameters)
      parsed.length.should == 3

      parsed[0][0].should == section1.sis_source_id
      parsed[0][1].should == course1.sis_source_id
      parsed[0][2].should == section1.name
      parsed[0][3].should == "active"
      parsed[0][4].should == start_at.iso8601
      parsed[0][5].should == end_at.iso8601
      parsed[0][6].should == sub_account.sis_source_id

      parsed[1][0].should == section2.sis_source_id
      parsed[1][1].should == course1.sis_source_id
      parsed[1][2].should == section2.name
      parsed[1][3].should == "active"
      parsed[1][4].should == nil
      parsed[1][5].should == end_at.iso8601
      parsed[1][6].should == nil

      parsed[2].should == ["english_section_3", "SIS_COURSE_ID_2", "Math_01", "active", nil, end_at.iso8601, nil]

    end

    it "should run the SIS Enrollments" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default

      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.save!
      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :account => @account, :enrollment_term => term1)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.save!
      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save!
      #this course should not be in the report since it does not have an sis id
      section1 = CourseSection.new(:name => 'sci_01', :course => course3)
      section1.sis_source_id = 'science_section_1'
      section1.root_account_id = @account.id
      section1.save!

      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:active_all => true, :account => @account, :name => "Rick Astley", :sortable_name => "Astley, Rick", :username => 'rick@roll.com')
      @user.pseudonym.sis_user_id = "user_sis_id_03"
      @user.pseudonym.save!
      user4 = user_with_pseudonym(:active_all => true, :username => 'jason@donovan.com', :name => 'Jason Donovan', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_04"
      @user.pseudonym.save!
      user5 = user_with_pseudonym(:name => 'James Brown', :account => @account)
      #user5 has no sis_id and should not be in the report
      user6 = user_with_pseudonym(:active_all => true, :username => 'john@smith.com', :name => 'John Smith',:sortable_name => "Smith, John", :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_06"
      @user.pseudonym.save!

      enrollment1 = course1.enroll_user(user1, 'ObserverEnrollment')
      enrollment1.invite
      enrollment1.accept
      enrollment1.save!
      enrollment2 = course3.enroll_user(user2, 'StudentEnrollment')
      enrollment2.invite
      enrollment2.accept
      enrollment2.save!
      enrollment3 = course1.enroll_user(user2, 'TaEnrollment')
      enrollment3.accept
      enrollment3.save!
      user2.reload
      enrollment4 = course1.enroll_user(user3, 'StudentEnrollment')
      enrollment4.invite
      enrollment4.accept
      enrollment4.save!
      enrollment5 = course2.enroll_user(user3, 'StudentEnrollment')
      enrollment5.invite
      enrollment5.accept
      enrollment5.save!
      user3.reload
      enrollment6 = course1.enroll_user(user4, 'TeacherEnrollment')
      enrollment6.accept
      enrollment6.save!
      enrollment7 = course2.enroll_user(user1, 'ObserverEnrollment')
      enrollment7.associated_user_id = user3.id
      enrollment7.invite
      enrollment7.accept
      enrollment7.save!
      user1.reload
      enrollment8 = course2.enroll_user(user5, 'TeacherEnrollment')
      enrollment8.accept
      enrollment8.save!
      user5.reload
      enrollment9 = section1.enroll_user(user4, 'TeacherEnrollment')
      enrollment9.accept
      enrollment9.save!
      user4.reload
      enrollment10 = course1.enroll_user(user6, 'TeacherEnrollment')
      enrollment10.accept
      enrollment10.save!
      enrollment10.workflow_state = 'completed'
      enrollment10.save!
      user6.reload

      parameters = {}
      parameters["enrollments"] = true
      parsed = run_report(parameters, 1)
      parsed.length.should == 7

      parsed[0].should == ["SIS_COURSE_ID_1", "user_sis_id_01", "observer", nil, "active", nil]
      parsed[1].should == ["SIS_COURSE_ID_2", "user_sis_id_01", "observer", nil, "active", "user_sis_id_03"]
      parsed[2].should == ["SIS_COURSE_ID_1", "user_sis_id_02", "ta", nil, "active", nil]
      parsed[3].should == ["SIS_COURSE_ID_1", "user_sis_id_03", "student", nil, "active", nil]
      parsed[4].should == ["SIS_COURSE_ID_2", "user_sis_id_03", "student", nil, "active", nil]
      parsed[5].should == ["SIS_COURSE_ID_1", "user_sis_id_04", "teacher", nil, "active", nil]
      parsed[6].should == [nil, "user_sis_id_04", "teacher", "science_section_1", "active", nil]

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["enrollments"] = true
      parsed = run_report(parameters, 1)
      parsed.length.should == 5

      parsed[0].should == ["SIS_COURSE_ID_1", "user_sis_id_01", "observer", nil, "active", nil]
      parsed[1].should == ["SIS_COURSE_ID_1", "user_sis_id_02", "ta", nil, "active", nil]
      parsed[2].should == ["SIS_COURSE_ID_1", "user_sis_id_03", "student", nil, "active", nil]
      parsed[3].should == ["SIS_COURSE_ID_1", "user_sis_id_04", "teacher", nil, "active", nil]
      parsed[4].should == [nil, "user_sis_id_04", "teacher", "science_section_1", "active", nil]

    end

    it "should run the SIS Groups" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!

      group1 = @account.groups.create(:name => 'group1name')
      group1.sis_source_id = 'group1sis'
      group1.save!
      group2 = sub_account.groups.create(:name => 'group2name')
      group2.sis_source_id = 'group2sis'
      group2.save!
      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["groups"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == ["group1sis", nil, "group1name", "available"]
      parsed[1].should == ["group2sis", "sub1", "group2name", "available"]

      parameters = {}
      parameters["groups"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == ["group1sis", nil, "group1name", "available"]
      parsed[1].should == ["group2sis", "sub1", "group2name", "available"]
    end

    it "should run the SIS Groups Memberships" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!

      group1 = @account.groups.create(:name => 'group1name')
      group1.sis_source_id = 'group1sis'
      group1.save!
      group2 = sub_account.groups.create(:name => 'group2name')
      group2.sis_source_id = 'group2sis'
      group2.save!
      gm1 = GroupMembership.create(:group => group1, :user => user1, :workflow_state => "accepted")
      gm1.sis_batch_id = 1
      gm1.save!
      gm2 = GroupMembership.create(:group => group2, :user => user2, :workflow_state => "accepted")
      gm2.sis_batch_id = 1
      gm2.save!

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["group_membership"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == [group1.sis_source_id, "user_sis_id_01", "accepted"]
      parsed[1].should == [group2.sis_source_id, "user_sis_id_02", "accepted"]

      parameters = {}
      parameters["group_membership"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == [group1.sis_source_id, "user_sis_id_01", "accepted"]
      parsed[1].should == [group2.sis_source_id, "user_sis_id_02", "accepted"]
    end

    it "should run the x list report" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!
      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account, :enrollment_term => term1)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.save!
      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :account => @account, :enrollment_term => term1)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.save!
      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save
      course3.sis_source_id = "SIS_COURSE_ID_3"
      course3.save!
      course4 = Course.new(:name => 'Science 1011', :course_code => 'SCI1011', :account => @account)
      course4.save
      course4.sis_source_id = "SIS_COURSE_ID_4"
      course4.save!
      section1 = CourseSection.new(:name => 'English_01', :course => course1)
      section1.sis_source_id = 'english_section_1'
      section1.root_account_id = @account.id
      section1.save!
      section2 = CourseSection.new(:name => 'English_02', :course => course2)
      section2.sis_source_id = 'english_section_2'
      section2.root_account_id = @account.id
      section2.save!
      section3 = CourseSection.new(:name => 'Math_01', :course => course3)
      section3.sis_source_id = 'english_section_3'
      section3.root_account_id = @account.id
      section3.save!
      section4 = CourseSection.new(:name => 'Math_012', :course => course4)
      section4.sis_source_id = 'english_section_4'
      section4.root_account_id = @account.id
      section4.save!

      section1.crosslist_to_course(course2)
      section3.crosslist_to_course(course4)

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["xlist"] = true
      parsed = run_report(parameters)
      parsed.length.should == 1
      parsed[0].should == ["SIS_COURSE_ID_4", "english_section_3", "active"]

      parameters = {}
      parameters["xlist"] = true
      parsed = run_report(parameters)
      parsed.length.should == 2
      parsed[0].should == ["SIS_COURSE_ID_2", "english_section_1", "active"]
      parsed[1].should == ["SIS_COURSE_ID_4", "english_section_3", "active"]
    end

    it "should run the SIS Export" do
      @account = Account.default
      @admin = account_admin_user(:account => @account)
      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:name => 'Rick Astley', :account => @account)
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!
      sub_sub_account = Account.create(:parent_account => sub_account, :name => 'ESL')
      sub_sub_account.sis_source_id = 'subsub1'
      sub_sub_account.save!
      sub_account2 = Account.create(:parent_account => @account, :name => 'Math')
      sub_account2.sis_source_id = 'sub2'
      sub_account2.save!
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!
      term2 = EnrollmentTerm.create(:name => 'Winter', :start_at => '07-01-2013', :end_at => '28-04-2013')
      term2.root_account = @account
      term2.sis_source_id = 'winter13'
      term2.save!
      start_at = 1.day.ago
      end_at = 10.days.from_now

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account, :enrollment_term => term1)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.restrict_enrollments_to_course_dates = true
      course1.save!

      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :conclude_at => end_at, :account => @account)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.restrict_enrollments_to_course_dates = true
      course2.save!

      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save
      course3.sis_source_id = "SIS_COURSE_ID_3"
      course3.save!

      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["courses"] = true
      parsed = run_report(parameters)

      accounts_report = parsed["accounts"][1..-1].sort_by { |r| r[0] }
      accounts_report[0].should == ["sub1", nil, "English", "active"]
      accounts_report[1].should == ["sub2", nil, "Math", "active"]
      accounts_report[2].should == ["subsub1", "sub1", "ESL", "active"]

      users_report = parsed["users"][1..-1].sort_by { |r| r[0] }
      users_report[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      users_report[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]

      courses_report = parsed["courses"][1..-1].sort_by { |r| r[0] }
      courses_report[0].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      courses_report[1].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]

      parameters = {}
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["courses"] = true
      parsed = run_report(parameters)

      accounts_report = parsed["accounts"][1..-1].sort_by { |r| r[0] }
      accounts_report[0].should == ["sub1", nil, "English", "active"]
      accounts_report[1].should == ["sub2", nil, "Math", "active"]
      accounts_report[2].should == ["subsub1", "sub1", "ESL", "active"]

      users_report = parsed["users"][1..-1].sort_by { |r| r[0] }
      users_report[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      users_report[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]

      courses_report = parsed["courses"][1..-1].sort_by { |r| r[0] }
      courses_report[0].should == ["SIS_COURSE_ID_1", "ENG101", "English 101", "sub1", "fall12", "active", start_at.iso8601, end_at.iso8601]
      courses_report[1].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      courses_report[2].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]
    end
    it "should run the SIS Export reports with no data" do
      @account = Account.default
      @admin = account_admin_user(:account => @account)
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      parameters = {}
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["terms"] = true
      parameters["courses"] = true
      parameters["sections"] = true
      parameters["enrollments"] = true
      parameters["groups"] = true
      parameters["group_membership"] = true
      parameters["xlist"] = true
      parsed = run_report(parameters)

      parsed["accounts"].should == [["account_id", "parent_account_id", "name", "status"]]
      parsed["terms"].should == [["term_id", "name", "status", "start_date", "end_date"]]
      parsed["users"].should == [["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]]
      parsed["courses"].should == [["course_id", "short_name", "long_name", "account_id", "term_id", "status", "start_date", "end_date"]]
      parsed["sections"].should == [["section_id", "course_id", "name", "status", "start_date", "end_date", "account_id"]]
      parsed["enrollments"].should == [["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]]
      parsed["groups"].should == [["group_id", "account_id", "name", "status"]]
      parsed["group_membership"].should == [["group_id", "user_id", "status"]]
      parsed["xlist"].should == [["xlist_course_id", "section_id", "status"]]
    end
  end

  it "should find the default module and configured reports" do
    CustomReportsSpecHelper.find_account_module_and_reports('default')
  end
end