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
require_relative '../pages/gradebook_page'

describe 'Original Gradebook' do
  include_context "in-process server selenium tests"

  before(:once) do
    # create a course with a teacher
    @teacher1 = course_with_teacher(course_name: 'Course1', active_all: true).user

    # enroll a second teacher
    @teacher2 = course_with_teacher(course: @course, name: 'Teacher2', active_all: true).user

    # enroll two students
    @student1 = course_with_student(course: @course, name: 'Student1', active_all: true).user
    @student2 = course_with_student(course: @course, name: 'Student2', active_all: true).user
  end

  context 'with an anonymous assignment' do
    before(:each) do
      # create an anonymous assignment
      @anonymous_assignment = @course.assignments.create!(
        title: 'Anonymous Assignment1',
        grader_count: 1,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_upload',
        anonymous_grading: true
      )

      @student1_submission = @anonymous_assignment.grade_student(@student1, grade: 13, grader: @teacher1)
      user_session(@teacher1)
    end

    context 'grade cells', priority: '1', test_id: 3496299 do
      before(:each) do
        Gradebook::MultipleGradingPeriods.visit_gradebook(@course)
      end

      it 'are disabled and hide grades when assignment is muted', priority: '1', test_id: 3496299 do
        grade_cell_grayed = Gradebook::MultipleGradingPeriods.grading_cell_content(0,0)
        class_attribute_fetched = grade_cell_grayed.attribute("class")

        expect(class_attribute_fetched).to include "grayed-out cannot_edit"
      end
    end
  end

  context 'with a moderated assignment' do
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

      # switch session to non-final-grader
      user_session(@teacher2)
    end

    it 'assignment cannot be unmuted in Gradebook before grades are posted', priority: '1', test_id: 3496195 do
      Gradebook::MultipleGradingPeriods.visit_gradebook(@course)
      Gradebook::MultipleGradingPeriods.assignment_header_menu_select(@moderated_assignment.id)
      wait_for_ajaximations

      expect(Gradebook::MultipleGradingPeriods.assignment_header_menu_item_find('Unmute Assignment').attribute('aria-disabled')).to eq 'true'
    end

    it 'assignment can be unmuted in Gradebook after grades are posted', priority: '1', test_id: 3496195 do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)

      Gradebook::MultipleGradingPeriods.visit_gradebook(@course)
      Gradebook::MultipleGradingPeriods.assignment_header_menu_select(@moderated_assignment.id)
      wait_for_ajaximations

      expect(Gradebook::MultipleGradingPeriods.assignment_header_menu_item_find('Unmute Assignment').attribute('aria-disabled')).to be nil
    end
  end
end
