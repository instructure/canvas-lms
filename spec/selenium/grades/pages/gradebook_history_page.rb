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
#
require_relative '../../helpers/gradezilla_common'
require_relative '../../common'


class GradeBookHistory
  class << self
  include SeleniumDependencies

  def visit(course)
    get "/courses/#{course.id}/gradebook/history"
  end

  def select_student_name(student_name)
    student_name_textfield.send_keys(student_name)
    select_data_from_dropdown(student_name)
  end

  def select_grader_name(grader_name)
    grader_name_textfield.send_keys(grader_name)
    select_data_from_dropdown(grader_name)
  end

  def select_assignment_name(assignment_name)
    assignment_name_textfield.send_keys(assignment_name)
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

  def enter_from_date(from_date)
    from_date_textfield.send_keys(from_date)
  end

  def enter_to_date(to_date)
    to_date_textfield.send_keys(to_date)
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
    # enter_student_name('user')
    # enter_grader_name('nobody')
    # enter_assignment_name('assignment one')
    # set_from_date('')
    # set_to_date('')
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

  def from_date_textfield
    f('')
  end

  def to_date_textfield
    f('')
  end

  def filter_button
    # f('#content button > span')
    # driver.find_element(:xpath, "//*[contains(text(), 'Filter')]")
    driver.find_element(:xpath,"//button[@type='submit']")
  end

  def results_table
    driver.find_element(:xpath, "//table")
  end

  def type_ahead_dropdown
    f('')
  end

  def results_table_rows
    # ff('#content > div > div.GradebookHistory__Results > div > div > table > tbody > tr')
    driver.find_elements(:xpath, "//table/tbody/tr")
  end

  def results_table_current_col(index)
    # f("#content>div>div:nth-child(2)>div:nth-child(1)>table>tbody>tr:nth-child(#{index})>td:nth-child(8)")
    driver.find_element(:xpath,"//table/tbody/tr[#{index}]/td[8]")
  end

  def results_table_assignment_col(index)
    # f("#content>div>div:nth-child(2)>div:nth-child(1)>table>tbody>tr:nth-child(#{index})>td:nth-child(8)")
    driver.find_element(:xpath,"//table/tbody/tr[#{index}]/td[8]")
  end

  end
end


