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

    parsed = ReportsSpecHelper.run_report(@account,'student_assignment_outcome_map_csv',{},1)
    parsed.length.should == 2

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
    term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
    term1.root_account = @account
    term1.sis_source_id = 'fall12'
    term1.save!
    student_in_course(:course => @course, :active_all => true, :name => 'Luke Skywalker')
    course1 = @course
    course1.sis_source_id = "SISr2d2"
    course1.name = 'robotics 101'
    course1.enrollment_term_id = term1.id
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

    enrollment1 = student0.enrollments.find_by_course_id(course1.id)
    enrollment1.computed_final_score = 88
    enrollment1.save!
    enrollment2 = @student1.enrollments.first
    enrollment2.computed_final_score = 90
    enrollment2.save!
    enrollment3 = @student.enrollments.first
    enrollment3.computed_final_score = 93
    enrollment3.save!
    enrollment4 = student0.enrollments.find_by_course_id(course2.id)
    enrollment4.computed_final_score = 98
    enrollment4.save!

    #should run for term1
    parameters = {}
    parameters["enrollment_term"] = term1.id
    parsed = ReportsSpecHelper.run_report(@account,'grade_export_csv',parameters,13)
    parsed.length.should == 2

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
    parsed[0][12].to_s.should == enrollment1.computed_current_score.to_s
    parsed[0][13].to_s.should == enrollment1.computed_final_score.to_s

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
    parsed[1][12].to_s.should == enrollment2.computed_current_score.to_s
    parsed[1][13].to_s.should == enrollment2.computed_final_score.to_s

    #should accept sis term ids
    parameters = {}
    parameters["enrollment_term"] = "sis_term_id:fall12"
    parsed = ReportsSpecHelper.run_report(@account,'grade_export_csv',parameters,13)
    parsed.length.should == 2

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
    parsed[0][12].to_s.should == enrollment1.computed_current_score.to_s
    parsed[0][13].to_s.should == enrollment1.computed_final_score.to_s

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
    parsed[1][12].to_s.should == enrollment2.computed_current_score.to_s
    parsed[1][13].to_s.should == enrollment2.computed_final_score.to_s

    #should run for all terms.
    parameters = {}
    parsed = ReportsSpecHelper.run_report(@account,'grade_export_csv',parameters,13)
    parsed.length.should == 4

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
    parsed[0][12].to_s.should == enrollment1.computed_current_score.to_s
    parsed[0][13].to_s.should == enrollment1.computed_final_score.to_s

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
    parsed[1][12].to_s.should == enrollment2.computed_current_score.to_s
    parsed[1][13].to_s.should == enrollment2.computed_final_score.to_s

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
    parsed[2][12].to_s.should == enrollment3.computed_current_score.to_s
    parsed[2][13].to_s.should == enrollment3.computed_final_score.to_s

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
    parsed[3][12].to_s.should == enrollment4.computed_current_score.to_s
    parsed[3][13].to_s.should == enrollment4.computed_final_score.to_s
  end

  it "should find the default module and configured reports" do
    ReportsSpecHelper.find_account_module_and_reports('default')
  end
end