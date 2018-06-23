#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/global_grades_page"
require_relative "../pages/student_grades_page"
require_relative "../pages/gradebook_page"
require_relative "../pages/student_interactions_report_page"

describe 'Global Grades' do
  include_context "in-process server selenium tests"

  SCORE1 = 90.0
  SCORE2 = 76.0
  SCORE3 = 9.0
  SCORE4 = 8.0
  SCORE5 = 47

  before(:once) do

    now = Time.zone.now

    # create a second term
    Account.default.enrollment_terms.create! name: "another term",
                                             start_at: 2.months.ago(now),
                                             end_at: 2.months.from_now(now)
    second_term = Account.default.enrollment_terms.second

    # create first course
    @course_no_gp = course_factory(active_all: true, course_name: "Course 1")
    @student = user_factory(active_all: true)
    @course_no_gp.enroll_student(@student, enrollment_state: 'active')


    # create a second course, associate with second term created above, and enroll student
    @course_with_gp = course_factory(course_name: "Course 2", active_course: true)
    @course_with_gp.enrollment_term_id = second_term.id
    @course_with_gp.save!
    @course_with_gp.reload
    @course_with_gp.enroll_teacher(@teacher, enrollment_state: 'active')
    @course_with_gp.enroll_student(@student, allow_multiple_enrollments: true, enrollment_state: 'active')

    # create grading periods associated with second term
    gpg = GradingPeriodGroup.new
    gpg.account_id = @course_with_gp.root_account
    gpg.save!
    gpg.grading_periods.create! start_date: 6.months.ago,
                                end_date: 3.months.ago,
                                close_date: 2.days.from_now(now),
                                title: "old grading period"
    gpg.grading_periods.create! start_date: 2.months.ago(now),
                                end_date:   2.months.from_now(now),
                                close_date: 3.months.from_now(now),
                                title: "current grading period"
    term = @course_with_gp.enrollment_term
    term.update_attribute :grading_period_group, gpg

    # create 3 assignments
    @assignment1 = @course_with_gp.assignments.create!(
      title: 'assignment one',
      grading_type: 'points',
      points_possible: 100,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @assignment2 = @course_with_gp.assignments.create!(
      title: 'assignment two',
      grading_type: 'points',
      points_possible: 100,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @assignment3 = @course_with_gp.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @assignment4 = @course_with_gp.assignments.create!(
      title: 'assignment 4',
      grading_type: 'points',
      points_possible: 10,
      due_at: 4.months.ago(now),
      submission_types: 'online_text_entry'
    )
    @assignment5 = @course_no_gp.assignments.create!(
      title: 'assignment 5',
      grading_type: 'points',
      points_possible: 50,
      due_at: 3.days.ago(now),
      submission_types: 'online_text_entry'
    )

    # Grade the assignments
    @assignment1.grade_student(@student, grade: SCORE1, grader: @teacher)
    @assignment2.grade_student(@student, grade: SCORE2, grader: @teacher)
    @assignment3.grade_student(@student, grade: SCORE3, grader: @teacher)
    @assignment4.grade_student(@student, grade: SCORE4, grader: @teacher)
    @assignment5.grade_student(@student, grade: SCORE5, grader: @teacher)

    GRADE_CURRENT_GP = ((SCORE1 + SCORE2 + SCORE3)/(@assignment1.points_possible + @assignment2.points_possible +
      @assignment3.points_possible))*100
    GRADE_OLD_GP = ((SCORE4/@assignment4.points_possible)*100)
    GRADE_TOTAL_GP = ((SCORE1 + SCORE2 + SCORE3 + SCORE4)/(@assignment1.points_possible + @assignment2.points_possible +
      @assignment3.points_possible + @assignment4.points_possible))*100
    GRADE_TOTAL_NO_GP = (SCORE5/@assignment5.points_possible)*100
  end

  context 'as student' do
    before(:each) do
      user_session(@student)

      # navigate to global grades page
      GlobalGrades.visit
    end

    it 'goes to student grades page', priority: "1", test_id: 3491485 do
      # grab score to compare
      course_score = GlobalGrades.get_score_for_course(@course_with_gp)
      # find link for Second Course and click
      wait_for_new_page_load(GlobalGrades.click_course_link(@course_with_gp))

      # verify url has correct course id
      expect(driver.current_url).to eq app_url + "/courses/#{@course_with_gp.id}/grades/#{@student.id}"
      # verify assignment score is correct
      expect(StudentGradesPage.final_grade.text).to eq(course_score)
    end

    it 'show score for grading period', priority: "1", test_id: 3501070 do
      GlobalGrades.select_grading_period(@course_with_gp, "old grading period")
      # verify course grade
      expect(GlobalGrades.get_score_for_course_no_percent(@course_with_gp)).to eq(GRADE_OLD_GP.round(2))
    end

    it 'show score for course without grading periods', priority: "1", test_id: 3501470 do
      expect(GlobalGrades.get_score_for_course_no_percent(@course_no_gp)).to eq(GRADE_TOTAL_NO_GP.round(2))
    end
  end

  context 'as teacher' do
    before(:each) do
      user_session(@teacher)

      # navigate to global grades page
      GlobalGrades.visit
    end

    it 'has grades table with courses', priority: "1", test_id: 3500053 do
      expect(GlobalGrades.course_details).to include_text(@course_no_gp.name)
      expect(GlobalGrades.course_details).to include_text(@course_with_gp.name)
    end

    it 'has grades table with student average' do # test id 350053
      expect(GlobalGrades.score(@course_with_gp)).to include_text("average for 1 student")
      # calculate expected grade average

      expect(GlobalGrades.get_score_for_course_no_percent(@course_with_gp)).to eq GRADE_TOTAL_GP.round(2)
    end

    it 'has grades table with interactions report' do # test id 350053
      expect(GlobalGrades.report(@course_with_gp)).to contain_link("Student Interactions Report")
    end

    it 'goes to gradebook page', priority: "1", test_id: 3494790 do
      # find link for Second Course and click
      wait_for_new_page_load(GlobalGrades.click_course_link(@course_with_gp))

      # verify url has correct course id
      expect(driver.current_url).to eq app_url + "/courses/#{@course_with_gp.id}/gradebook"
      # verify assignment score is correct
      expect(Gradebook::MultipleGradingPeriods.student_total_grade(@student)).to eq("#{GRADE_CURRENT_GP.round(2)}%")
    end

    it 'goes to student interactions report', priority: "1", test_id: 3500433 do
      GlobalGrades.click_report_link(@course_with_gp)

      expect(StudentInteractionsReport.report).to be_displayed
      # verify current score
      expect(StudentInteractionsReport.current_score(@student.name)).to eq("#{GRADE_TOTAL_GP.round(1)}%")
    end
  end
end
