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

module PacePlansPageObject
  #------------------------- Selectors -------------------------------
  def assignment_due_date_selector
    "[data-testid='assignment-due-date']"
  end

  def cancel_button_selector
    "button:contains('Cancel')"
  end

  def compression_tooltip_selector
    "[data-testid='duedate-tooltip']"
  end

  def duration_field_selector
    "[data-testid='duration-number-input']"
  end

  def duration_readonly_selector
    "[data-testid='duration-input']"
  end

  def edit_tray_close_button_selector
    "button:contains('Close')"
  end

  def hypothetical_end_date_selector
    "[data-testid='pace-plans-collapse']:contains('Hypothetical end date')"
  end

  def module_item_points_possible_selector
    ".pace-plans-assignment-row-points-possible"
  end

  def module_item_publish_status_selector
    "[name='IconPublish']"
  end

  def module_item_unpublish_status_selector
    "[name='IconUnpublished']"
  end

  def module_items_selector
    "[data-testid='pp-title-cell']"
  end

  def pace_plan_end_date_selector
    "[data-testid='paceplan-date-text']"
  end

  def pace_plan_menu_selector
    "[data-position-target='pace-plan-menu']"
  end

  def pace_plan_picker_selector
    "[data-testid='pace-plan-picker']"
  end

  def pace_plan_student_option_selector
    "[data-position-target='pace-plan-student-menu']"
  end

  def pace_plans_page_selector
    "#pace_plans"
  end

  def pace_plan_start_date_selector
    "[data-testid='pace-plan-date']"
  end

  def pace_plan_table_module_selector
    "h2"
  end

  def publish_button_selector
    "button:contains('Publish')"
  end

  def publish_status_button_selector
    "[data-testid='publish-status-button']"
  end

  def publish_status_selector
    "[data-testid='publish-status']"
  end

  def require_end_date_checkbox_xpath_selector
    "//label[..//input[@data-testid = 'require-end-date-toggle']]"
  end

  def require_end_date_checkbox_selector
    "[data-testid='require-end-date-toggle']"
  end

  def required_end_date_input_selector
    "#pace-plans-required-end-date-input [data-testid='pace-plan-date']"
  end

  def required_end_date_message_selector
    "#pace-plans-required-end-date-input:contains('Required by specified end date')"
  end

  def settings_button_selector
    "button:contains('Modify Settings')"
  end

  def show_hide_button_with_icon_selector
    "[data-testid='projections-icon-button']"
  end

  def show_hide_pace_plans_selector
    "[data-test-id='projections-text-button']"
  end

  def skip_weekends_checkbox_xpath_selector
    "//label[..//input[@data-testid = 'skip-weekends-toggle']]"
  end

  def skip_weekends_checkbox_selector
    "[data-testid='skip-weekends-toggle']"
  end

  def student_menu_selector
    "ul[aria-label='Students']"
  end

  def student_pace_plan_selector(student_name)
    "span[role=menuitem]:contains(#{student_name})"
  end

  def student_pp_xpath_selector(student_name)
    "//ul[@aria-label = 'Students']//span[text() = '#{student_name}']"
  end

  def students_menu_item_selector
    "button:contains('Students')"
  end

  def unpublished_changes_list_selector
    "[aria-label='Unpublished Changes tray'] li"
  end

  def unpublished_changes_tray_selector
    "[aria-label='Unpublished Changes tray']"
  end

  def unpublished_warning_modal_selector
    "[data-testid='unpublished-warning-modal']"
  end

  #------------------------- Elements --------------------------------

  def assignment_due_date
    f(assignment_due_date_selector)
  end

  def cancel_button
    fj(cancel_button_selector)
  end

  def compression_tooltip
    f(compression_tooltip_selector)
  end

  def duration_field
    f(duration_field_selector)
  end

  def duration_readonly
    f(duration_readonly_selector)
  end

  def edit_tray_close_button
    fj(edit_tray_close_button_selector)
  end

  def hypothetical_end_date
    fj(hypothetical_end_date_selector)
  end

  def module_item_points_possible
    ff(module_item_points_possible_selector)
  end

  def module_item_publish_status
    ff(module_item_publish_status_selector)
  end

  def module_item_unpublish_status
    ff(module_item_unpublish_status_selector)
  end

  def module_items
    ff(module_items_selector)
  end

  def module_item_title(item_title)
    flnpt(item_title)
  end

  def pace_plan_end_date
    f(pace_plan_end_date_selector)
  end

  def pace_plan_menu
    ff(pace_plan_menu_selector)
  end

  def pace_plan_picker
    f(pace_plan_picker_selector)
  end

  def pace_plan_student_option
    f(pace_plan_student_option_selector)
  end

  def pace_plans_page
    f(pace_plans_page_selector)
  end

  def pace_plan_start_date
    f(pace_plan_start_date_selector)
  end

  def pace_plan_table_module_elements
    ff(pace_plan_table_module_selector)
  end

  def publish_button
    fj(publish_button_selector)
  end

  def publish_status
    f(publish_status_selector)
  end

  def publish_status_button
    f(publish_status_button_selector)
  end

  def require_end_date_checkbox
    fxpath(require_end_date_checkbox_xpath_selector)
  end

  def required_end_date_input
    f(required_end_date_input_selector)
  end

  def required_end_date_message
    fj(required_end_date_message_selector)
  end

  def settings_button
    fj(settings_button_selector)
  end

  def show_hide_button_with_icon
    f(show_hide_button_with_icon_selector)
  end

  def show_hide_pace_plans
    f(show_hide_pace_plans_selector)
  end

  def skip_weekends_checkbox
    fxpath(skip_weekends_checkbox_xpath_selector)
  end

  def student_pace_plan(student_name)
    fj(student_pace_plan_selector(student_name))
  end

  def students_menu_item
    fj(students_menu_item_selector)
  end

  def unpublished_changes_list
    ff(unpublished_changes_list_selector)
  end

  def unpublished_changes_tray
    f(unpublished_changes_tray_selector)
  end

  def unpublished_warning_modal
    f(unpublished_warning_modal_selector)
  end

  #----------------------- Actions & Methods -------------------------
  def visit_pace_plans_page
    get "/courses/#{@course.id}/pace_plans"
  end

  #----------------------- Click Items -------------------------------

  def click_cancel_button
    cancel_button.click
  end

  def click_edit_tray_close_button
    edit_tray_close_button.click
  end

  def click_main_pace_plan_menu
    pace_plan_picker.click
  end

  def click_require_end_date_checkbox
    require_end_date_checkbox.click
  end

  def click_settings_button
    settings_button.click
  end

  def click_show_hide_projections_button
    show_hide_pace_plans.click
  end

  def click_skip_weekends_toggle
    skip_weekends_checkbox.click
  end

  def click_student_pace_plan(student_name)
    # This check reduces the flakiness of the clicking in this menu.  Keeping
    # the puts line for verification in the logs
    unless element_exists?(student_pp_xpath_selector(student_name), true)
      puts "Student pace plan selector didn't exist so retrying click"
      click_students_menu_item
    end

    student_pace_plan(student_name).click
  end

  def click_students_menu_item
    unless element_exists?(pace_plan_student_option_selector)
      puts "retrying the main menu click"
      click_main_pace_plan_menu
    end
    pace_plan_student_option.click
    # Reducing the flakiness of this menu
    unless element_exists?(student_menu_selector)
      pace_plan_student_option.click
    end
  end

  def click_unpublished_changes_button
    publish_status_button.click
  end

  def click_weekends_checkbox
    skip_weekends_checkbox.click
  end

  #------------------------------Retrieve Text------------------------
  #
  def module_item_title_text(item_number)
    module_items[item_number].text
  end

  def module_title_text(element_number)
    pace_plan_table_module_elements[element_number].text
  end

  delegate :text, to: :pace_plans_page, prefix: true

  #----------------------------Element Management---------------------

  def add_required_end_date(required_end_date)
    required_end_date_input.send_keys([:control, "a"], :backspace, format_date_for_view(required_end_date), :enter)
  end

  def add_start_date(start_date)
    pace_plan_start_date.send_keys([:control, "a"], :backspace, format_date_for_view(start_date), :enter)
  end

  delegate :text, to: :assignment_due_date, prefix: true

  def calculate_saturday_date
    current_date = Date.today
    current_date + ((6 - current_date.wday) % 7)
  end

  def module_item_exists?
    element_exists?(module_items_selector)
  end

  def pace_plan_end_date_exists?
    element_exists?(pace_plan_end_date_selector)
  end

  def pace_plan_menu_value
    element_value_for_attr(pace_plan_menu[1], "value")
  end

  def pace_plan_start_date_exists?
    element_exists?(pace_plan_start_date_selector)
  end

  def publish_status_exists?
    element_exists?(publish_status_selector)
  end

  def publish_status_button_exists?
    element_exists?(publish_status_button_selector)
  end

  def required_end_date_input_exists?
    element_exists?(required_end_date_input_selector)
  end

  def required_end_date_value
    element_value_for_attr(required_end_date_input, "value")
  end

  def show_hide_pace_plans_button_text
    show_hide_pace_plans.text
  end

  def show_hide_pace_plans_exists?
    element_exists?(show_hide_pace_plans_selector)
  end

  def show_hide_icon_button_exists?
    element_exists?(show_hide_button_with_icon_selector)
  end

  def skip_weekends_exists?
    element_exists?(skip_weekends_checkbox_xpath_selector, true)
  end

  def update_module_item_duration(duration)
    duration_field.send_keys([:control, "a"], :backspace, duration, :tab)
  end

  def unpublished_changes_tray_exists?
    element_exists?(unpublished_changes_tray_selector)
  end
end
