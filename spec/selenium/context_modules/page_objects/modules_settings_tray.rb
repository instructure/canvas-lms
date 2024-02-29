# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module ModulesSettingsTray
  #------------------------------ Selectors -----------------------------
  def add_module_tray_selector
    "[aria-label='Add Module']"
  end

  def add_prerequisites_button_selector
    "//*[@data-testid = 'prerequisite-form']//button[.//*[.='Prerequisite']]"
  end

  def add_requirement_button_selector
    "//*[@data-testid = 'settings-panel']//button[.//*[.='Requirement']]"
  end

  def assign_to_panel_selector
    "[data-testid='assign-to-panel']"
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

  def assign_to_tab_selector
    "#tab-assign-to"
  end

  def clear_all_selector
    "[data-testid='clear_selection_button']"
  end

  def complete_all_radio_click_selector
    "//label[../input[@data-testid = 'complete-all-radio']]"
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

  def custom_access_radio_checked_selector
    "[data-testid = 'custom-option']"
  end

  def custom_access_radio_click_selector
    "//label[../input[@data-testid = 'custom-option']]"
  end

  def everyone_radio_checked_selector
    "[data-testid = 'everyone-option']"
  end

  def everyone_radio_click_selector
    "//label[../input[@data-testid = 'everyone-option']]"
  end

  def header_label_selector
    "[data-testid='header-label']"
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

  def module_name_input_selector
    "[data-testid='module-name-input']"
  end

  def module_requirement_card_selector
    "[data-testid='module-requirement-card']"
  end

  def module_settings_tray_selector
    "[aria-label='Edit Module Settings']"
  end

  def number_input_selector(requirement_number)
    "#NumberInput_#{requirement_number}"
  end

  def prerequisites_dropdown_selector
    "//*[starts-with(@id, 'prerequisite-')]"
  end

  def prerequisite_message_selector(context_module)
    "#context_module_#{context_module.id} .prerequisites_message"
  end

  def remove_prerequisite_button_selector
    "//button[.//*[contains(text(),'Remove')]]"
  end

  def remove_requirement_button_selector
    "//button[.//*[contains(text(), 'Content Requirement')]]"
  end

  def requirement_item_selector
    "//*[starts-with(@id, 'requirement-item-')]"
  end

  def requirement_type_selector
    "//*[starts-with(@id, 'requirement-type-')]"
  end

  def sequential_order_checkbox_selector
    "//label[../input[@data-testid='sequential-progress-checkbox']]"
  end

  def settings_panel_selector
    "[data-testid='settings-panel']"
  end

  def settings_tab_selector
    "#tab-settings"
  end

  def settings_tray_button_selector(tray_label, button_label)
    "//*[@aria-label='#{tray_label}']//button[.//*[. = '#{button_label}']]"
  end

  #------------------------------ Elements ------------------------------
  def add_module_tray
    f(add_module_tray_selector)
  end

  def add_prerequisites_button
    fxpath(add_prerequisites_button_selector)
  end

  def add_requirement_button
    fxpath(add_requirement_button_selector)
  end

  def add_tray_add_module_button
    fxpath(settings_tray_button_selector("Add Module", "Add Module"))
  end

  def add_tray_cancel_button
    fxpath(settings_tray_button_selector("Add Module", "Cancel"))
  end

  def add_tray_close_button
    fxpath(settings_tray_button_selector("Add Module", "Close"))
  end

  def assign_to_panel
    f(assign_to_panel_selector)
  end

  def assign_to_tab
    f(assign_to_tab_selector)
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

  def complete_all_radio_checked
    f(complete_all_radio_checked_selector)
  end

  def complete_all_radio_click
    fxpath(complete_all_radio_click_selector)
  end

  def complete_one_radio_checked
    f(complete_one_radio_checked_selector)
  end

  def complete_one_radio_click
    fxpath(complete_one_radio_click_selector)
  end

  def custom_access_radio_checked
    f(custom_access_radio_checked_selector)
  end

  def custom_access_radio_click
    fxpath(custom_access_radio_click_selector)
  end

  def everyone_radio_checked
    f(everyone_radio_checked_selector)
  end

  def everyone_radio_click
    fxpath(everyone_radio_click_selector)
  end

  def header_label
    f(header_label_selector)
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

  def module_name_input
    f(module_name_input_selector)
  end

  def module_requirement_card
    ff(module_requirement_card_selector)
  end

  def module_settings_tray
    f(module_settings_tray_selector)
  end

  def number_input(requirement_number)
    f(number_input_selector(requirement_number))
  end

  def prerequisites_dropdown
    ffxpath(prerequisites_dropdown_selector)
  end

  def prerequisite_message(context_module)
    f(prerequisite_message_selector(context_module))
  end

  def remove_prerequisite_button
    ffxpath(remove_prerequisite_button_selector)
  end

  def remove_requirement_button
    ffxpath(remove_requirement_button_selector)
  end

  def requirement_item
    ffxpath(requirement_item_selector)
  end

  def requirement_type
    ffxpath(requirement_type_selector)
  end

  def sequential_order_checkbox
    fxpath(sequential_order_checkbox_selector)
  end

  def settings_panel
    f(settings_panel_selector)
  end

  def settings_tab
    f(settings_tab_selector)
  end

  def settings_tray_update_module_button
    fxpath(settings_tray_button_selector("Edit Module Settings", "Save"))
  end

  def settings_tray_close_button
    fxpath(settings_tray_button_selector("Edit Module Settings", "Close"))
  end

  def settings_tray_cancel_button
    fxpath(settings_tray_button_selector("Edit Module Settings", "Cancel"))
  end

  #------------------------------ Actions ------------------------------
  def add_module_tray_exists?
    element_exists?(add_module_tray_selector)
  end

  def add_prerequisites_button_exists?
    element_exists?(add_prerequisites_button_selector, true)
  end

  def click_add_prerequisites_button
    add_prerequisites_button.click
  end

  def click_add_requirement_button
    add_requirement_button.click
  end

  def click_add_tray_add_module_button
    add_tray_add_module_button.click
  end

  def click_add_tray_cancel_button
    add_tray_cancel_button.click
  end

  def click_add_tray_close_button
    add_tray_close_button.click
  end

  def click_assign_to_tab
    assign_to_tab.click
  end

  def click_clear_all
    clear_all.click
  end

  def click_complete_all_radio
    complete_all_radio_click.click
  end

  def click_complete_one_radio
    complete_one_radio_click.click
  end

  def click_custom_access_radio
    custom_access_radio_click.click
  end

  def click_everyone_radio
    everyone_radio_click.click
  end

  def click_lock_until_checkbox
    lock_until_checkbox.click
  end

  def click_remove_prerequisite_button(item_number)
    remove_prerequisite_button[item_number].click
  end

  def click_remove_requirement_button(item_number)
    remove_requirement_button[item_number].click
  end

  def click_sequential_order_checkbox
    sequential_order_checkbox.click
  end

  def click_settings_tab
    settings_tab.click
  end

  def click_settings_tray_cancel_button
    settings_tray_cancel_button.click
  end

  def click_settings_tray_close_button
    settings_tray_close_button.click
  end

  def click_settings_tray_update_module_button
    settings_tray_update_module_button.click
  end

  def prerequisites_dropdown_value(dropdown_list_item)
    element_value_for_attr(prerequisites_dropdown[dropdown_list_item], "value")
  end

  def select_prerequisites_dropdown_option(item_number, option)
    click_option(prerequisites_dropdown[item_number], option)
  end

  def select_requirement_item_option(item_number, option)
    click_option(requirement_item[item_number], option)
  end

  def select_requirement_type_option(item_number, option)
    click_option(requirement_type[item_number], option)
  end

  def settings_tray_exists?
    element_exists?(module_settings_tray_selector)
  end

  def update_lock_until_date(date)
    replace_content(lock_until_date, date, tab_out: true)
  end

  def update_lock_until_time(time)
    replace_content(lock_until_time, time, tab_out: true)
  end

  def update_module_name(new_name)
    replace_content(module_name_input, new_name)
  end
end
