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

describe 'Global Grades' do
  include_context "in-process server selenium tests"

  SCORE1 = 90.0
  SCORE2 = 76.0
  SCORE3 = 9.0

  before(:once) do

    now = Time.zone.now

    @ungraded_course = course_factory(active_all: true, course_name: "Course 1")
    @student = user_factory(active_all: true)
    @ungraded_course.enroll_student(@student, enrollment_state: 'active')

    # create a second course and enroll student
    @graded_course = course_factory(course_name: "Course 2", active_course: true)
    @graded_course.enroll_teacher(@teacher, enrollment_state: 'active')
    @graded_course.enroll_student(@student, allow_multiple_enrollments: true, enrollment_state: 'active')

    # create 3 assignments
    @assignment1 = @graded_course.assignments.create!(
      title: 'assignment one',
      grading_type: 'points',
      points_possible: 100,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @assignment2 = @graded_course.assignments.create!(
      title: 'assignment two',
      grading_type: 'points',
      points_possible: 100,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @assignment3 = @graded_course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: now,
      submission_types: 'online_text_entry'
    )

    # Grade the assignments
    @assignment1.grade_student(@student, grade: SCORE1, grader: @teacher)
    @assignment2.grade_student(@student, grade: SCORE2, grader: @teacher)
    @assignment3.grade_student(@student, grade: SCORE3, grader: @teacher)
  end

  context 'as student' do
    before(:each) do
      user_session(@student)

      # navigate to global grades page
      GlobalGrades.visit
    end

    it 'goes to student grades page', priority: "1", test_id: 3491485 do
      # grab score to compare
      course_score = GlobalGrades.get_score_for_course(@graded_course)
      # find link for Second Course and click
      wait_for_new_page_load(GlobalGrades.click_course_link(@graded_course))

      # verify url has correct course id
      expect(driver.current_url).to eq app_url + "/courses/#{@graded_course.id}/grades/#{@student.id}"
      # verify assignment score is correct
      expect(StudentGradesPage.final_grade.text).to eq(course_score)
    end
  end

  context 'as teacher' do
    before(:each) do
      user_session(@teacher)

      # navigate to global grades page
      GlobalGrades.visit
    end

    it 'has grades table with courses', priority: "1", test_id: 3500053 do
      expect(GlobalGrades.course_details).to include_text(@ungraded_course.name)
      expect(GlobalGrades.course_details).to include_text(@graded_course.name)
    end

    it 'has grades table with student average' do # test id 350053
      expect(GlobalGrades.score(@graded_course)).to include_text("average for 1 student")
      # calculate expected grade average
      grade = ((SCORE1 + SCORE2 + SCORE3)/(@assignment1.points_possible + @assignment2.points_possible + @assignment3.points_possible))*100
      expect(GlobalGrades.get_score_for_course_no_percent(@graded_course)).to eq grade.round(2)
    end

    it 'has grades table with interactions report' do # test id 350053
      expect(GlobalGrades.report(@graded_course)).to contain_link("Student Interactions Report")
    end

    it 'goes to gradebook page', priority: "1", test_id: 3494790 do
      # grab scores to compare
      course_score = GlobalGrades.get_score_for_course(@graded_course)
      # find link for Second Course and click
      wait_for_new_page_load(GlobalGrades.click_course_link(@graded_course))

      # verify url has correct course id
      expect(driver.current_url).to eq app_url + "/courses/#{@graded_course.id}/gradebook"
      # verify assignment score is correct
      expect(Gradebook::MultipleGradingPeriods.student_total_grade(@student)).to eq(course_score)
    end
  end
end
