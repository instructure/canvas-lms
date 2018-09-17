#
# Copyright (C) 2017 - present Instructure, Inc.
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

class GradeBookHistory
  class << self
    include SeleniumDependencies

    def visit(course)
      get "/courses/#{course.id}/gradebook/history"
    end

    def select_student_name(typeahead, student_name)
      enter_student_name(typeahead)
      select_data_from_dropdown(student_name)
    end

    def select_grader_name(grader_name)
      enter_grader_name(grader_name)
      select_data_from_dropdown(grader_name)
    end

    def select_assignment_name(assignment_name)
      enter_assignment_name(assignment_name)
      select_data_from_dropdown(assignment_name)
    end

    def enter_student_name(student_name)
      student_name_textfield.send_keys(student_name)
      wait_for_ajaximations
    end

    def enter_grader_name(grader_name)
      grader_name_textfield.send_keys(grader_name)
      wait_for_ajaximations
    end

    def enter_assignment_name(assignment_name)
      assignment_name_textfield.send_keys(assignment_name)
      wait_for_ajaximations
    end

    def enter_start_date(from_date)
      start_date_textfield.send_keys(from_date)
    end

    def enter_end_date(to_date)
      end_date_textfield.send_keys(to_date)
    end

    def click_filter_button
      filter_button.click
      wait_for_ajaximations
    end

    def select_data_from_dropdown(text)
      fj("[role=listbox] [role=option]:contains('#{text}')").click
      wait_for_ajaximations
    end

    def edit_grade(grade)
      grade_edit_textfield.send_keys(grade)
    end

    def fetch_results_table_row_count
      results_table_rows.size
    end

    def search_with_student_name(type_ahead, student)
      select_student_name(type_ahead, student)
      click_filter_button
    end

    def search_with_grader_name(grader)
      select_grader_name(grader)
      click_filter_button
    end

    def search_with_assignment_name(assignment)
      select_assignment_name(assignment)
      click_filter_button
    end

    def search_with_all_data(type_ahead, student, grader, assignment)
      select_student_name(type_ahead, student)
      select_grader_name(grader)
      select_assignment_name(assignment)
      click_filter_button
    end

    def check_current_col_for_history(assignment_name)
      row_elements = results_table_rows
      current_grade_arr=Array.[]
      for index in 1...row_elements.size
        if results_table_assignment_col(index).text == assignment_name
          current_grade_arr[index] = results_table_current_col(index).text
        end
      end
      check_arr_unique_element(current_grade_arr)
    end

    def check_table_for_assignment_name(string_in_row)
      row_elements = results_table_rows
      test_passed = true
      for index in 1...row_elements.size
        if results_table_assignment_col(index).text != string_in_row
          test_passed = false
        end
      end
      test_passed
    end

    def check_table_for_grader_name(string_in_row)
      row_elements = results_table_rows
      test_passed = true
      for index in 1...row_elements.size
        if results_table_grader_col(index).text != string_in_row
          test_passed = false
        end
      end
      test_passed
    end

    def check_table_for_student_name(string_in_row)
      row_elements = results_table_rows
      test_passed = true
      for index in 1...row_elements.size
        if results_table_student_col(index).text != string_in_row
          test_passed = false
        end
      end
      test_passed
    end

    def check_arr_unique_element(arr)
      test_passed = false
      unless arr.uniq.size == 1
        test_passed = true
      end
      test_passed
    end

    def student_name_textfield
      f('#students')
    end

    def grader_name_textfield
      f('#graders')
    end

    def assignment_name_textfield
      f('#assignments')
    end

    def start_date_textfield
      driver.find_element(:id, fj('label:contains("Start Date")')[:for])
    end

    def end_date_textfield
      driver.find_element(:id, fj('label:contains("End Date")')[:for])
    end

    def error_text_invalid_dates
      fxpath("(//span[contains(text(), 'date must be before')])[2]")
    end

    def filter_button
      find_button('Filter')
    end

    def results_table
      find_table('Grade Changes')
    end

    def results_table_rows
      ffxpath("//table/tbody/tr")
    end

    def results_table_current_col(row_index)
      fxpath_table_cell("Grade Changes", row_index, 8)
    end

    def results_table_assignment_col(row_index)
      fxpath_table_cell("Grade Changes", row_index, 5)
    end

    def results_table_grader_col(row_index)
      fxpath_table_cell("Grade Changes", row_index, 4)
    end

    def results_table_student_col(row_index)
      fxpath_table_cell("Grade Changes", row_index, 3)
    end
  end
end
