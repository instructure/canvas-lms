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

describe 'Global Grades' do
  include_context "in-process server selenium tests"
  let(:student_grades_page) {StudentGradesPage.new}

  before(:once) do

    now = Time.zone.now

    course_factory(active_all: true, course_name: "Course 1")
    student_in_course(active_all: true)

    # create a second course and enroll student
    @course2 = course_with_teacher(user: @teacher, course_name: "Course 2").course
    @course2.enroll_student(@student, allow_multiple_enrollments: true).accept(true)
    @course2.offer!

    # create 3 assignments
    @assignment1 = @course2.assignments.create!(
      title: 'assignment one',
      grading_type: 'points',
      points_possible: 100,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @a2 = @course2.assignments.create!(
      title: 'assignment two',
      grading_type: 'points',
      points_possible: 100,
      due_at: now,
      submission_types: 'online_text_entry'
    )
    @a3 = @course2.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: now,
      submission_types: 'online_text_entry'
    )

    # Grade the assignments
    @assignment1.grade_student(@student, grade: 90, grader: @teacher)
    @a2.grade_student(@student, grade: 76, grader: @teacher)
    @a3.grade_student(@student, grade: 9, grader: @teacher)
  end

  before(:each) do
    user_session(@student)

    # navigate to global grades page
    GlobalGrades.visit
  end

  it 'goes to student grades page', priority: "1", test_id: 3491485 do
    # grab score to compare
    course_score = GlobalGrades.get_score_for_course(@course2)
    # find link for Second Course and click
    GlobalGrades.click_course_link(@course2)

    # verify url has correct course id
    expect(driver.current_url).to eq app_url + "/courses/#{@course2.id}/grades/#{@student.id}"
    # verify assignment score is correct
    expect(student_grades_page.final_grade.text).to eq(course_score)
  end

end
