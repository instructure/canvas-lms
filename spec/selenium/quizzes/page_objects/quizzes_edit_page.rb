# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module QuizzesEditPage
  # --------------------------------Selectors----------------------------------
  def manage_assign_to_button_selector
    "[data-testid='manage-assign-to']"
  end

  def pending_changes_pill_selector
    "[data-testid='pending_changes_pill']"
  end

  def quiz_save_button_selector
    ".save_quiz_button"
  end

  # ---------------------------------Elements-----------------------------------

  def course_pacing_notice
    "[data-testid='CoursePacingNotice']"
  end

  def due_date_container
    ".ContainerDueDate"
  end

  def manage_assign_to_button
    f(manage_assign_to_button_selector)
  end

  def pending_changes_pill
    f(pending_changes_pill_selector)
  end

  def quiz_edit_form
    "form#quiz_options_form"
  end

  def quiz_save_button
    f(quiz_save_button_selector)
  end

  # ---------------------------------Methods------------------------------------

  def click_manage_assign_to_button
    f(manage_assign_to_button_selector).click
  end

  def click_quiz_save_button
    quiz_save_button.click
  end

  def pending_changes_pill_exists?
    element_exists?(pending_changes_pill_selector)
  end

  def retrieve_quiz_due_date_table_row(row_item)
    row_elements = f(".assignment_dates").find_elements(:tag_name, "tr")
    row_elements.detect { |i| i.text.include?(row_item) }
  end

  def submit_page
    wait_for_new_page_load { click_quiz_save_button }
    expect(driver.current_url).not_to include("edit")
  end
end
