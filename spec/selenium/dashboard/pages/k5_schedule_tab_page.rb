# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../../helpers/color_common"

module K5ScheduleTabPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------

  def calendar_event_modal_selector
    "[aria-label='Calendar Event Details']"
  end

  def close_calendar_event_modal_selector
    "//button[.//*[. = 'Close']]"
  end

  def close_editor_modal_selector
    "[data-testid='close-editor-modal']"
  end

  def missing_assignments_selector
    ".MissingAssignments-styles__root .PlannerItem-styles__details"
  end

  def missing_data_selector
    "[data-testid = 'missing-data']"
  end

  def missing_dropdown_selector
    "[data-testid = 'missing-item-info']"
  end

  def next_week_button_selector
    "//button[.//span[. = 'View next week']]"
  end

  def previous_week_button_selector
    "//button[.//span[. = 'View previous week']]"
  end

  def schedule_item_selector
    ".PlannerItem-styles__details a"
  end

  def teacher_preview_selector
    "h2:contains('Schedule Preview')"
  end

  def today_button_selector
    "//button[.//span[. = 'Today']]"
  end

  def today_selector
    "h2 div:contains('Today')"
  end

  def todo_edit_pencil_selector
    ".PlannerItem-styles__editButton button[cursor='pointer']"
  end

  def todo_editor_modal_selector
    "[data-testid='todo-editor-modal']"
  end

  def todo_item_selector
    ".PlannerItem-styles__title button"
  end

  def todo_save_button_selector
    "//button[.//*[. = 'Save']]"
  end

  def todo_title_input_selector(todo_title)
    "[value='#{todo_title}']"
  end

  def week_date_selector
    "h2 div"
  end

  #------------------------- Elements --------------------------

  def assignment_link(missing_assignment_element, course_id, assignment_id)
    find_from_element_fxpath(missing_assignment_element, missing_item_href_selector(course_id, assignment_id))
  end

  def beginning_of_week_date
    date_block = ff(week_date_selector)
    (date_block[0].text == "Today") ? date_block[1].text : date_block[0].text
  end

  def calendar_event_modal
    f(calendar_event_modal_selector)
  end

  def close_calendar_event_modal
    fxpath(close_calendar_event_modal_selector)
  end

  def close_editor_modal
    f(close_editor_modal_selector)
  end

  def end_of_week_date
    ff(week_date_selector).last.text
  end

  def items_missing
    f(missing_dropdown_selector)
  end

  def items_missing_exists?
    element_exists?(missing_dropdown_selector)
  end

  def missing_assignments
    ff(missing_assignments_selector)
  end

  def missing_data
    f(missing_data_selector)
  end

  def next_week_button
    fxpath(next_week_button_selector)
  end

  def planner_assignment_header
    f(planner_assignment_header_selector)
  end

  def previous_week_button
    fxpath(previous_week_button_selector)
  end

  def schedule_item
    f(schedule_item_selector)
  end

  def teacher_preview
    fj(teacher_preview_selector)
  end

  def today_button
    fxpath(today_button_selector)
  end

  def today_header
    fj(today_selector)
  end

  def todo_edit_pencil
    f(todo_edit_pencil_selector)
  end

  def todo_editor_modal
    f(todo_editor_modal_selector)
  end

  def todo_item
    f(todo_item_selector)
  end

  def todo_save_button
    fxpath(todo_save_button_selector)
  end

  def todo_title_input(todo_title)
    f(todo_title_input_selector(todo_title))
  end

  #----------------------- Actions & Methods -------------------------

  #----------------------- Click Items -------------------------------

  def click_close_calendar_event_modal
    close_calendar_event_modal.click
  end

  def click_close_editor_modal_button
    close_editor_modal.click
  end

  def click_missing_items
    driver.execute_script("arguments[0].scrollIntoView()", items_missing)
    items_missing.click
  end

  def click_next_week_button
    next_week_button.click
  end

  def click_previous_week_button
    previous_week_button.click
  end

  def click_today_button
    today_button.click
  end

  def click_todo_edit_pencil
    todo_edit_pencil.click
  end

  def click_todo_item
    todo_item.click
  end

  def click_todo_save_button
    todo_save_button.click
  end

  #------------------------------Retrieve Text----------------------#

  #----------------------------Element Management---------------------#

  def calendar_modal_exists?
    element_exists?(calendar_event_modal_selector)
  end

  def missing_assignments_exist?
    element_exists?(missing_assignments_selector)
  end

  def missing_data_exists?
    element_exists?(missing_data_selector)
  end

  def schedule_item_exists?
    element_exists?(schedule_item_selector)
  end

  def todo_modal_exists?
    element_exists?(todo_editor_modal_selector)
  end

  def update_todo_title(old_todo_title, new_todo_title)
    todo_element = todo_title_input(old_todo_title)
    replace_content(todo_element, new_todo_title)
  end

  #------------------------Helper Methods------------------------#

  def beginning_weekday_calculation(current_date)
    current_date.beginning_of_week(:sunday).strftime("%B %-d")
  end

  def ending_weekday_calculation(current_date)
    current_date.end_of_week(:sunday).strftime("%B %-d")
  end
end
