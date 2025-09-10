# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Modules2ActionTray
  #------------------------------ Selectors -----------------------------
  def add_module_tray_selector
    "div[role='dialog'][aria-label='Add Module']"
  end

  def prerequisites_dropdown_selector
    "//*[starts-with(@id, 'prerequisite-')]"
  end

  def add_module_button_selector
    "#context-modules-header-add-module-button"
  end

  def custom_access_radio_click_selector
    "//label[../input[@data-testid = 'custom-option']]"
  end

  def delete_card_button_selector
    "[data-testid = 'delete-card-button']"
  end

  def tray_header_label_selector
    "h2[data-testid='header-label']"
  end

  def input_module_name_selector
    "[data-testid='module-name-input']"
  end

  def submit_add_module_button_selector
    "button[data-testid='differentiated_modules_save_button']"
  end

  def module_settings_tray_selector
    "[aria-label='Edit Module Settings']"
  end

  def everyone_radio_checked_selector
    "[data-testid = 'everyone-option']"
  end

  def custom_access_radio_checked_selector
    "[data-testid = 'custom-option']"
  end

  def assignee_selection_selector
    "[data-testid='assignee_selector']"
  end

  def assignee_selection_item_selector
    "[data-testid='assignee_selector_selected_option']"
  end

  def assignee_selection_item_remove_selector(assignee)
    "//*[@data-testid='assignee_selector_selected_option']//*[contains(@title, 'Remove #{assignee}')]"
  end

  def clear_all_selector
    "[data-testid='clear_selection_button']"
  end

  def module_index_menu_tool_link_selector(tool_text)
    "[role=menuitem]:contains('#{tool_text}')"
  end

  def assign_to_error_message_selector
    "#TextInput-messages___0"
  end

  def convert_differentiated_tag_button_selector
    "[data-testid='convert-differentiation-tags-button']"
  end

  def lock_until_checkbox_selector
    "//label[../input[@data-testid='lock-until-checkbox']]"
  end

  def lock_until_date_selector
    "//*[@data-testid = 'lock-until-input']//*[contains(@class,'-dateInput')]//input"
  end

  def lock_until_input_selector
    "[data-testid='lock-until-input']"
  end

  def lock_until_time_selector
    "//*[@data-testid = 'lock-until-input']//*[contains(@class, '-select')]//input"
  end

  def add_requirement_button_selector
    "[data-testid='add-requirement-button']"
  end

  def add_prerequisite_button_selector
    "[data-testid='add-prerequisite-button']"
  end

  def complete_all_radio_checked_selector
    "[data-testid = 'complete-all-radio']"
  end

  def complete_one_radio_click_selector
    "//label[../input[@data-testid = 'complete-one-radio']]"
  end

  def complete_one_radio_checked_selector
    "[data-testid = 'complete-one-radio']"
  end

  def sequential_order_checkbox_selector
    "//label[../input[@data-testid='sequential-progress-checkbox']]"
  end

  def module_requirement_card_selector
    "[data-testid='module-requirement-card']"
  end

  def requirement_item_selector
    "//*[starts-with(@id, 'requirement-item-')]"
  end

  def requirement_type_selector
    "//*[starts-with(@id, 'requirement-type-')]"
  end

  def remove_requirement_button_selector(content_name)
    "//button[.//*[contains(text(), 'Remove #{content_name} Content Requirement')]]"
  end

  def add_item_modal_selector
    "[data-testid='add-item-modal']"
  end

  def add_item_create_new_item_form_tab_selector
    "#tab-create-item-form"
  end

  def add_item_upload_file_form_selector
    "[data-testid='module-file-drop'] input"
  end

  def add_item_indent_select_selector
    "[data-testid='add-item-indent-selector']"
  end

  #------------------------------ Elements ------------------------------
  def add_module_button
    f(add_module_button_selector)
  end

  def add_module_tray
    f(add_module_tray_selector)
  end

  def custom_access_radio_click
    fxpath(custom_access_radio_click_selector)
  end

  def delete_card_button
    ff(delete_card_button_selector)
  end

  def tray_header_label
    f(tray_header_label_selector)
  end

  def input_module_name
    f(input_module_name_selector)
  end

  def lock_until_checkbox
    fxpath(lock_until_checkbox_selector)
  end

  def lock_until_date
    fxpath(lock_until_date_selector)
  end

  def lock_until_input
    f(lock_until_input_selector)
  end

  def lock_until_time
    fxpath(lock_until_time_selector)
  end

  def add_prerequisite_button
    f(add_prerequisite_button_selector)
  end

  def prerequisites_dropdown
    ffxpath(prerequisites_dropdown_selector)
  end

  def prerequisites_dropdown_value(dropdown_list_item)
    element_value_for_attr(prerequisites_dropdown[dropdown_list_item], "value")
  end

  def submit_add_module_button
    f(submit_add_module_button_selector)
  end

  def module_settings_tray
    f(module_settings_tray_selector)
  end

  def everyone_radio_checked
    f(everyone_radio_checked_selector)
  end

  def custom_access_radio_checked
    f(custom_access_radio_checked_selector)
  end

  def assignee_selection
    f(assignee_selection_selector)
  end

  def assignee_selection_item
    ff(assignee_selection_item_selector)
  end

  def assignee_selection_item_remove(assignee)
    fxpath(assignee_selection_item_remove_selector(assignee))
  end

  def clear_all
    f(clear_all_selector)
  end

  def module_index_menu_tool_link(tool_text)
    fj(module_index_menu_tool_link_selector(tool_text))
  end

  def assign_to_error_message
    f(assign_to_error_message_selector)
  end

  def convert_differentiated_tag_button
    f(convert_differentiated_tag_button_selector)
  end

  def add_requirement_button
    f(add_requirement_button_selector)
  end

  def complete_all_radio_checked
    f(complete_all_radio_checked_selector)
  end

  def complete_one_radio_checked
    f(complete_one_radio_checked_selector)
  end

  def complete_one_radio_click
    fxpath(complete_one_radio_click_selector)
  end

  def sequential_order_checkbox
    fxpath(sequential_order_checkbox_selector)
  end

  def module_requirement_card
    ff(module_requirement_card_selector)
  end

  def requirement_item
    ffxpath(requirement_item_selector)
  end

  def requirement_type
    ffxpath(requirement_type_selector)
  end

  def select_requirement_item_option(item_number, option)
    click_option(requirement_item[item_number], option)
  end

  def select_requirement_type_option(item_number, option)
    click_option(requirement_type[item_number], option)
  end

  def remove_requirement_button(content_name)
    fxpath(remove_requirement_button_selector(content_name))
  end

  def add_item_create_new_item_form_tab
    f(add_item_create_new_item_form_tab_selector)
  end

  def add_item_upload_file_form
    f(add_item_upload_file_form_selector)
  end

  def add_item_modal
    f(add_item_modal_selector)
  end

  def add_item_indent_select
    f(add_item_indent_select_selector)
  end
  #------------------------------ Actions -------------------------------

  def click_custom_access_radio
    custom_access_radio_click.click
  end

  def fill_in_module_name(name)
    replace_content(input_module_name, name)
  end

  def select_prerequisites_dropdown_option(item_number, option)
    click_option(prerequisites_dropdown[item_number], option)
  end

  def settings_tray_exists?
    element_exists?(module_settings_tray_selector)
  end

  def click_lock_until_checkbox
    expect(lock_until_checkbox).to be_displayed
    lock_until_checkbox.click
  end

  def update_lock_until_date(date)
    replace_content(lock_until_date, date, tab_out: true)
  end

  def update_lock_until_time(time)
    replace_content(lock_until_time, time, tab_out: true)
  end

  def click_add_requirement_button
    expect(add_requirement_button).to be_displayed
    add_requirement_button.click
  end

  def click_add_prerequisites_button
    expect(add_prerequisite_button).to be_displayed
    add_prerequisite_button.click
  end

  def select_complete_one_radio
    expect(complete_one_radio_click).to be_displayed
    complete_one_radio_click.click
  end

  def click_save_module_tray_change
    submit_add_module_button.click
    wait_for_ajaximations
  end

  def click_add_item_create_new_item_tab
    add_item_create_new_item_form_tab.click
    expect(create_learning_object_name_input).to be_displayed
  end
end
