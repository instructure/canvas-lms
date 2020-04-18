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

require_relative '../pages/gradebook_cells_page'
require_relative '../pages/gradebook_page'
require_relative '../pages/gradebook_grade_detail_tray_page'
require_relative '../pages/moderate_page'

describe 'New Gradebook' do
  include_context 'in-process server selenium tests'

  before(:once) do
    # create a course with a teacher
    @teacher1 = course_with_teacher(course_name: 'Course1', active_all: true).user
    @student1 = student_in_course(active_all: true).user
  end

  context 'with an anonymous assignment' do
    before(:once) do
      # create a regular non-anonymous assignment
      @non_anonymous_assignment = @course.assignments.create!(
        title: 'Non Anonymous Assignment',
        submission_types: 'online_text_entry',
        points_possible: 10
      )
    end

    before(:each) do
      # create a new anonymous assignment
      @anonymous_assignment = @course.assignments.create!(
        title: 'Anonymous Assignment',
        submission_types: 'online_text_entry',
        anonymous_grading: true,
        points_possible: 10
      )

      @anonymous_assignment.grade_student(@student1, grade: '2', grader: @teacher1)

      user_session(@teacher1)
      Gradebook.visit(@course)
    end

    it 'score cell disabled in grade detail tray', priority: '1', test_id: 3500571 do
      Gradebook::Cells.open_tray(@student1, @anonymous_assignment)
      expect(Gradebook::GradeDetailTray.grade_input).to have_attribute('disabled', 'true')
    end

    it 'causes score cells to be greyed out with grades invisible when grades are not posted', priority: '1', test_id: 3504000 do
      grid_cell = Gradebook::Cells.grid_assignment_row_cell(@student1, @anonymous_assignment)
      class_attribute_fetched = grid_cell.attribute('class')
      expect(class_attribute_fetched).to include 'grayed-out'
      expect(Gradebook::Cells.get_grade(@student1, @anonymous_assignment)).to eq ''
    end

    it 'causes score cells to be not greyed out with grades visible when grades are posted', priority: '1', test_id: 3504000 do
      Gradebook.manually_post_grades(@anonymous_assignment, 'Everyone')
      Gradebook::Cells.edit_grade(@student1, @anonymous_assignment, '12')
      expect(Gradebook::Cells.get_grade(@student1, @anonymous_assignment)).to eq '12'
    end
  end

  context 'with a moderated assignment' do
    before(:once) do
      @teacher2 = course_with_teacher(course: @course, name: 'Teacher2', active_all: true).user
      @teacher3 = course_with_teacher(course: @course, name: 'Teacher3', active_all: true).user
    end

    before(:each) do
      # create moderated assignment
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment1',
        grader_count: 2,
        final_grader_id: @teacher1.id,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_text_entry',
        moderated_grading: true
      )

      # give a grade as non-final grader
      @moderated_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)
    end

    it 'prevents posting grades before they are released', priority: '1', test_id: 3496196 do
      user_session(@teacher1)
      ModeratePage.visit(@course.id, @moderated_assignment.id)
      ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)

      Gradebook.visit(@course)
      Gradebook.click_assignment_header_menu(@moderated_assignment.id)
      wait_for_ajaximations

      expect(Gradebook.assignment_menu_selector('No grades to post')).to be_displayed
    end

    it 'allows posting grades after they are released', priority: '1', test_id: 3496196 do
      user_session(@teacher1)
      ModeratePage.visit(@course.id, @moderated_assignment.id)
      ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)

      ModeratePage.click_release_grades_button
      driver.switch_to.alert.accept
      wait_for_ajaximations

      Gradebook.visit(@course)
      Gradebook.click_assignment_header_menu(@moderated_assignment.id)
      wait_for_ajaximations

      expect(Gradebook.assignment_menu_selector('Post grades')).to be_displayed
    end

    context "causes editing grades to be" do
      before(:each) do
        user_session(@teacher1)
        Gradebook.visit(@course)
      end

      it "not allowed until grades are posted", priority: "1", test_id: 3501496 do
        grid_cell = Gradebook::Cells.grid_assignment_row_cell(@student1, @moderated_assignment)
        class_attribute_fetched = grid_cell.attribute('class')
        expect(class_attribute_fetched).to include 'grayed-out cannot_edit'
      end

      it "allowed if grades are posted", priority: "1", test_id: 3501496 do
        @moderated_assignment.update!(grades_published_at: Time.zone.now)
        @moderated_assignment.unmute!
        refresh_page
        Gradebook::Cells.edit_grade(@student1, @moderated_assignment, '12')
        expect(Gradebook::Cells.get_grade(@student1, @moderated_assignment)).to eq '12'
      end
    end
  end
end
