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

require_relative '../../common'
require_relative '../pages/moderate_page'
require_relative '../pages/speedgrader_page'

GRADES = [["10", "8"].freeze, ["9", "7"].freeze, ["5", "3"].freeze].freeze

describe 'Moderation Page' do
  include_context 'in-process server selenium tests'

  before(:once) do

    @moderated_course = course_factory(course_name: "Moderated Course")
    # create and enroll 4 teachers in course
    @teachers = create_users_in_course(@moderated_course, 4, return_type: :record, name_prefix: "Boss", enrollment_type: 'TeacherEnrollment')
    # create 25 students enrolled in moderated_course
    @students = create_users_in_course(@moderated_course, 25, return_type: :record, name_prefix: "Slave")

    # create moderated assignment with teacher4 as final grader
    @assignment = @moderated_course.assignments.create!(
      title: 'moderated assignment',
      grader_count: 3,
      final_grader_id: @teachers[3].id,
      submission_types: 'online_text_entry',
      grading_type: 'points',
      points_possible: 10,
      moderated_grading: true
    )

    # teachers 2 and 3 grade the assignment for students 1 and 2
    (1..2).map do |i|
      @assignment.grade_student(@students[0], grade: GRADES[i][0], grader: @teachers[i], provisional: true)
      @assignment.grade_student(@students[1], grade: GRADES[i][1], grader: @teachers[i], provisional: true)
    end
    # grade the rest of the students, one grader to student
    (2..8).map do |i|
      @assignment.grade_student(@students[i], grade: Random.rand(11), grader: @teachers[0], provisional: true)
    end
    (9..16).map do |i|
      @assignment.grade_student(@students[i], grade: Random.rand(11), grader: @teachers[1], provisional: true)
    end
    (17..24).map do |i|
      @assignment.grade_student(@students[i], grade: Random.rand(11), grader: @teachers[2], provisional: true)
    end
  end

  before(:each) do
    user_session(@teachers[3])
    ModeratePage.visit(@moderated_course.id, @assignment.id)
  end

  it 'displays graders', priority: "1", test_id: 3505169 do
    expect(ModeratePage.fetch_grader_count).to equal(3)
    expect(ModeratePage.grader_names).to contain_exactly(@teachers[0].name, @teachers[1].name, @teachers[2].name)
  end

  it 'displays grades', priority: "1", test_id: 3505169 do
    expect(ModeratePage.fetch_grades(@students[0])).to contain_exactly(GRADES[1][0], GRADES[2][0], '–')
    expect(ModeratePage.fetch_grades(@students[1])).to contain_exactly(GRADES[1][1], GRADES[2][1], '–')
  end

  it 'displays first 20 students', priority: "1", test_id: 3505169 do
    expect(ModeratePage.fetch_student_count).to eq(20)
  end

  it 'displays page 2 with remaining students', priority: "1", test_id: 3505169 do
    ModeratePage.click_page_number(2)
    expect(ModeratePage.fetch_student_count).to eq 5
  end

  it 'navigates to the student submission in speedgrader', priority: "1", test_id: 3638363 do
    ModeratePage.click_student_link(@students[1].name)
    expect(Speedgrader.selected_student).to include_text @students[1].name
  end

  it 'navigates to an anonymous student submission in speedgrader', priority: "1", test_id: 3638364 do
    @assignment.update_attribute :anonymous_grading, true
    refresh_page
    ModeratePage.click_student_link("Student 1")
    expect(Speedgrader.selected_student).to include_text 'Student 1'
  end

  it 'accepts all grades for provisional grader', priority: "1", test_id: 3513993 do
    ModeratePage.accept_grades_for_grader(@teachers[0])

    (2..8).map do |i|
      expect(ModeratePage.fetch_selected_final_grade_text(@students[i])).to include(@teachers[0].name)
    end
  end

  it 'will not accept grades when more than one grader', priority: "1", test_id: 3513993 do
    expect(ModeratePage.accept_grades_button(@teachers[1])).to be_disabled
  end
end
