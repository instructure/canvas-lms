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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/srgb_page'
require_relative '../pages/speedgrader_page'

describe "Individual View Gradebook" do
  include_context 'in-process server selenium tests'
  include GradebookCommon

  before(:each) do
    # create a course with a teacher
    course_with_teacher(course_name: 'Course1', active_all: true)

    # enroll two students
    @student1 = User.create!(name: 'Student1')
    @student1.register!
    @course.enroll_student(@student1, enrollment_state: 'active')

    @student2 = User.create!(name: 'Student2')
    @student2.register!
    @course.enroll_student(@student2, enrollment_state: 'active')
  end

  context 'with a moderated assignment' do
    before(:each) do
      # enroll a second teacher
      @teacher2 = User.create!(name: 'Teacher2')
      @teacher2.register!
      @course.enroll_teacher(@teacher2, enrollment_state: 'active')

      # create moderated assignment
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment1',
        grader_count: 2,
        final_grader_id: @teacher.id,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_text_entry',
        moderated_grading: true
      )

      # enroll a student
      @student1 = User.create!(name: 'Student1')
      @student1.register!
      @course.enroll_student(@student1, enrollment_state: 'active')

      # give a grade as non-final grader
      @student1_submission = @moderated_assignment.submit_homework(@student1, :body => 'student 1 submission moderated assignment')
      @student1_submission = @moderated_assignment.grade_student(@student1, grade: 13, grader: @teacher2, provisional: true).first

      # switch session to non-final-grader
      user_session(@teacher2)
    end

    it 'prevents unmuting the assignment before grades are posted', priority: '2', test_id: 3504343 do
      SRGB.visit(@course.id)
      SRGB.select_assignment(@moderated_assignment)
      wait_for_ajaximations
      scroll_into_view('#assignment_muted_check')

      expect(SRGB.assignment_muted_checkbox.attribute('checked')).to eq 'true'
      expect(SRGB.assignment_muted_checkbox.attribute('disabled')).to eq 'true'
    end

    it 'allows unmuting the assignment after grades are posted', priority: '2', test_id: 3504343 do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)

      SRGB.visit(@course.id)
      SRGB.select_assignment(@moderated_assignment)
      wait_for_ajaximations
      scroll_into_view('#assignment_muted_check')

      expect(SRGB.assignment_muted_checkbox.attribute('disabled')).to be nil
    end

    it 'prevents grading for the assignment before grades are posted', priority: '2', test_id: 3505171 do
      SRGB.visit(@course.id)
      SRGB.select_student(@student1)
      SRGB.select_assignment(@moderated_assignment)
      scroll_into_view('#student_and_assignment_grade')

      expect(SRGB.main_grade_input.attribute('disabled')).to eq 'true'
    end

    it 'allows grading for the assignment after grades are posted', priority: '2', test_id: 3505171 do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)
      SRGB.visit(@course.id)
      SRGB.select_student(@student1)
      SRGB.select_assignment(@moderated_assignment)

      SRGB.enter_grade('15')
      expect(SRGB.current_grade).to eq '15'
    end
  end

  context 'with an anonymous assignment' do
    before(:each) do
      # create a new anonymous assignment
      @anonymous_assignment = @course.assignments.create!(
        title: 'Anonymous Assignment',
        submission_types: 'online_text_entry',
        anonymous_grading: true,
        points_possible: 10
      )

      # create an unmuted anonymous assignment
      @unmuted_anonymous_assignment = @course.assignments.create!(
        title: 'Unmuted Anon Assignment',
        submission_types: 'online_text_entry',
        anonymous_grading: true,
        points_possible: 10
      )
      @unmuted_anonymous_assignment.unmute!

      user_session(@teacher)
      SRGB.visit(@course.id)
    end

    it 'excludes the muted assignment from the assignment list', priority: '1', test_id: 3505168 do
      SRGB.select_student(@student1)
      SRGB.assignment_dropdown.click

      # muted anonymous assignment is not displayed
      expect(SRGB.assignment_dropdown).not_to include_text 'Anonymous Assignment'
      # unmuted anonymous assignment is displayed
      expect(SRGB.assignment_dropdown).to include_text 'Unmuted Anon Assignment'
    end

    it 'hides student names in speedgrader', priority: '2', test_id: 3505167 do
      # Open speedgrader for the anonymous assignment
      SRGB.select_assignment(@anonymous_assignment)
      scroll_into_view('#assignment-speedgrader-link')
      SRGB.speedgrader_link.click
      wait_for_ajaximations

      # open the student list dropdown
      Speedgrader.students_dropdown_button.click

      # ensure the student names are anonymized
      student_names = Speedgrader.students_select_menu_list.map(&:text)
      expect(student_names).to eql ['Student 1', 'Student 2']
    end
  end
end
