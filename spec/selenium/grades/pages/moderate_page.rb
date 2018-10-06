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

class ModeratePage
  class << self
    include SeleniumDependencies

    # Actions

    def visit(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}/moderate"
    end

    def select_provisional_grade_for_student_by_position(student, position)
      grade_input(student).click
      grade_input_dropdown_list(student)[position].click
    end

    def click_post_grades_button
      post_grades_button.click
    end

    def click_display_to_students_button
      display_to_students_button.click
    end

    def click_page_number(page_number)
      page_buttons.find {|e| e.text == page_number.to_s}.click
    end

    def enter_custom_grade(student, grade)
      grade_input(student).click
      grade_input(student).send_keys(:backspace, grade)
      grade_input_dropdown_list(student).find {|k| k.text == "#{grade} (Custom)"}.click
    end

    def click_student_link(student)
      wait_for_new_page_load{ student_link(student).click }
    end

    def fetch_selected_final_grade_text(student)
      grade_input(student).click
      text = grade_input_dropdown_list(student).find{|e| e.attribute('aria-selected') == "true"}.text
      # close the menu
      grade_input(student).send_keys(:escape)
      text
    end

    def accept_grades_for_grader(grader)
      accept_grades_button(grader).click
      # wait for Accepted button to exist
      fj("tr#grader-row-#{grader.id} button:contains('Accepted')")
    end

    # Methods

    def fetch_student_count
      student_table_row_headers.size
    end

    def fetch_provisional_grade_count_for_student(student)
      grades(student).size
    end

    def fetch_grader_count
      student_table_headers.size
    end

    def grader_names
      student_table_headers.map(&:text)
    end

    def fetch_grades(student)
      grades(student).map(&:text)
    end

    def fetch_dropdown_grades(student)
      grade_input_dropdown_list(student).map(&:text)
    end

    # Components

    def main_content_area
      f("#main")
    end

    def accept_grades_button(grader)
      fj("tr#grader-row-#{grader.id} button:contains('Accept')")
    end

    def student_table_headers
      ff('.GradesGrid__GraderHeader')
    end

    def student_table_row_headers
      ff('.GradesGrid__BodyRowHeader')
    end

    def student_table_row_by_displayed_name(name)
      fj(".GradesGrid__BodyRow:contains('#{name}')")
    end

    def post_grades_button
      fj("button:contains('Post')")
    end

    def grades_posted_button
      fj("button:contains('Grades Posted')")
    end

    def display_to_students_button
      fj("button:contains('Display to Students')")
    end

    def grades_visible_to_students_button
      fj("button:contains('Grades Visible to Students')")
    end

    def page_buttons
      ffxpath('//div[@role="navigation"]//button')
    end

    def grades(student)
      ff('.GradesGrid__ProvisionalGradeCell', student_table_row_by_displayed_name(student.name))
    end

    def grade_input(student)
      f('input', student_table_row_by_displayed_name(student.name))
    end

    def grade_input_dropdown_list(student)
      ff('li', student_table_row_by_displayed_name(student.name))
    end

    def grade_input_dropdown(student)
      f('ul', student_table_row_by_displayed_name(student.name))
    end

    def student_link(student_name)
      fj(".GradesGrid__BodyRow a:contains('#{student_name}')")
    end
  end
end
