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

require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_grade_detail_tray_page'

describe 'New Gradebook' do
  include_context 'in-process server selenium tests'

  before(:each) do
    # create a course with a teacher
    course_with_teacher(course_name: 'Course1', active_all: true)
  end

  context 'with an anonymous assignment' do
    before(:each) do
      @student1 = student_in_course.user

      # create a new anonymous assignment
      @anonymous_assignment = @course.assignments.create!(
        title: 'Anonymous Assignment',
        submission_types: 'online_text_entry',
        anonymous_grading: true,
        points_possible: 10
      )

      # create a regular non-anonymous assignment
      @non_anonymous_assignment = @course.assignments.create!(
        title: 'Non Anonymous Assignment',
        submission_types: 'online_text_entry',
        points_possible: 10
      )
    end

    it 'score cell disabled in grade detail tray', priority: '1', test_id: 3500571 do
      user_session(@teacher)
      Gradezilla.visit(@course)
      Gradezilla::Cells.open_tray(@student1, @anonymous_assignment)

      expect(Gradezilla::GradeDetailTray.grade_input).to have_attribute('aria-disabled', 'true')
    end

    it 'existing assignment is muted when anonymous-grading is enabled', priority: '1', test_id: 3500572 do
      expect(@non_anonymous_assignment.muted?).to be false
      # make the assignment anonymous
      @non_anonymous_assignment.update!(anonymous_grading: true)

      expect(@non_anonymous_assignment.muted?).to be true
    end

    context 'causes score cells to be' do
      before(:each) do
        user_session(@teacher)
        Gradezilla.visit(@course)
      end

      it 'greyed out with grades invisible when assignment is muted', priority: '1', test_id: 3504000 do
        grid_cell = Gradezilla::Cells.grid_assignment_row_cell(@student1, @anonymous_assignment)
        class_attribute_fetched = grid_cell.attribute('class')
        expect(class_attribute_fetched).to include 'grayed-out'
        expect(Gradezilla::Cells.get_grade(@student1, @anonymous_assignment)).to eq ''
      end

      it 'not greyed out with grades visible when assignment is unmuted', priority: '1', test_id: 3504000 do
        Gradezilla.toggle_assignment_muting(@anonymous_assignment.id)
        Gradezilla::Cells.edit_grade(@student1, @anonymous_assignment, '12')
        expect(Gradezilla::Cells.get_grade(@student1, @anonymous_assignment)).to eq '12'
      end
    end
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
      @student1_submission = @moderated_assignment.submit_homework(@student1, body: 'student 1 submission moderated assignment')
      @student1_submission = @moderated_assignment.grade_student(@student1, grade: 13, grader: @teacher2, provisional: true).first

      # switch session to non-final-grader
      user_session(@teacher2)
    end

    it 'displays "MUTED" in the assignment', priority: '1', test_id: 3496196 do
      Gradezilla.visit(@course)

      expect(Gradezilla.select_assignment_header_secondary_label(@moderated_assignment.name).text).to include 'MUTED'
    end

    it 'prevents unmuting the assignment before grades are posted', prirotiy: '1', test_id: 3496196 do
      Gradezilla.visit(@course)
      Gradezilla.click_assignment_header_menu(@moderated_assignment.id)
      wait_for_ajaximations

      expect(Gradezilla.assignment_menu_selector('Unmute Assignment').attribute('aria-disabled')).to eq 'true'
    end

    it 'allows unmuting the assignment after grades are posted', priority: '1', test_id: 3496196 do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)

      Gradezilla.visit(@course)
      Gradezilla.click_assignment_header_menu(@moderated_assignment.id)
      wait_for_ajaximations

      expect(Gradezilla.assignment_menu_selector('Unmute Assignment').attribute('aria-disabled')).to be nil
    end

    context "causes editing grades to be" do
      before(:each) do
        user_session(@teacher)
        Gradezilla.visit(@course)
      end

      it "not allowed until grades are posted", priority: "1", test_id: 3501496 do
        grid_cell = Gradezilla::Cells.grid_assignment_row_cell(@student1, @moderated_assignment)
        class_attribute_fetched = grid_cell.attribute('class')
        expect(class_attribute_fetched).to include 'muted grayed-out cannot_edit'
      end

      it "allowed if grades are posted ",priority: "1", test_id: 3501496 do
        @moderated_assignment.update!(grades_published_at: Time.zone.now)
        @moderated_assignment.unmute!
        refresh_page
        Gradezilla::Cells.edit_grade(@student1, @moderated_assignment, '12')
        expect(Gradezilla::Cells.get_grade(@student1, @moderated_assignment)).to eq '12'
      end
    end
  end
end
