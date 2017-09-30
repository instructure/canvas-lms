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

    def select_student_name(student_name)
      enter_student_name(student_name)
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
    end

    def enter_grader_name(grader_name)
      grader_name_textfield.send_keys(grader_name)
    end

    def enter_assignment_name(assignment_name)
      assignment_name_textfield.send_keys(assignment_name)
    end

    def enter_start_date(from_date)
      start_date_textfield.send_keys(from_date)
    end

    def enter_end_date(to_date)
      end_date_textfield.send_keys(to_date)
    end

    def click_filter_button
      filter_button.click
    end

    def select_data_from_dropdown(to_be_selected) end

    def edit_grade(grade)
      grade_edit_textfield.send_keys(grade)
    end

    def fetch_results_table_row_count
      results_table_rows.size
    end

    def search_with_all_data
      enter_student_name('Student')
      enter_grader_name('Grader One')
      enter_assignment_name('Assignment One')
      enter_start_date(1.day.ago(now))
      enter_end_date(1.day.from_now(now))
      click_filter_button
    end

    def check_current_col_for_history(assignment_name)
      row_elements= results_table_rows
      current_grade_arr=Array.[]
      for index in 1...row_elements.size
        if results_table_assignment_col(index).text == assignment_name
          current_grade_arr[index] = results_table_col(index).text
        end
      end
      check_arr_unique_element(current_grade_arr)
    end

    def check_arr_unique_element(arr)
      test_passed = false
      unless arr.uniq.size == 1
        test_passed = true
      end
      test_passed
    end

    # private

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
      driver.find_element(:xpath,"//*[contains(text(),'Start Date')]/../../following-sibling::span[1]/span/input")
    end

    def end_date_textfield
      driver.find_element(:xpath,"//*[contains(text(),'End Date')]/../../following-sibling::span[1]/span/input")
    end

    def error_text_invalid_dates
      driver.find_element(:xpath,"(//span[contains(text(), 'date must be before')])[2]")
    end

    def filter_button
      f("button[type='submit']")
    end

    def filter_button_for_aria
       driver.find_element(:xpath,"//button[@type='submit']")
    end

    def results_table
      driver.find_element(:xpath, "//table")
    end

    def type_ahead_dropdown() end

    def results_table_rows
      driver.find_elements(:xpath, "//table/tbody/tr")
    end

    def results_table_current_col(index)
      driver.find_element(:xpath,"//table/tbody/tr[#{index}]/td[8]")
    end

    def results_table_assignment_col(index)
      driver.find_element(:xpath,"//table/tbody/tr[#{index}]/td[8]")
    end
  end
end
