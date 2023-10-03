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
  def add_prerequisites_button_selector
    "//*[@data-testid = 'settings-panel']//button[.//*[.='Prerequisite']]"
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

  def module_settings_tray_selector
    "[aria-label='Edit Module Settings']"
  end

  def prerequisites_dropdown_selector
    "#prerequisite"
  end

  def prerequisite_message_selector(context_module)
    "#context_module_#{context_module.id} .prerequisites_message"
  end

  def remove_prerequisite_button_selector
    "//button[contains(text(), 'Remove Prerequisite')]"
  end

  def settings_panel_selector
    "[data-testid='settings-panel']"
  end

  def settings_tab_selector
    "#tab-settings"
  end

  def settings_tray_cancel_button_selector
    "//*[@aria-label='Edit Module Settings']//button[.//*[. = 'Cancel']]"
  end

  def settings_tray_close_button_selector
    "//*[@aria-label='Edit Module Settings']//button[.//*[. = 'Close']]"
  end

  def settings_tray_update_module_button_selector
    "//*[@aria-label='Edit Module Settings']//button[.//*[. = 'Update Module']]"
  end

  #------------------------------ Elements ------------------------------

  def add_prerequisites_button
    fxpath(add_prerequisites_button_selector)
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

  def module_settings_tray
    f(module_settings_tray_selector)
  end

  def prerequisites_dropdown
    ff(prerequisites_dropdown_selector)
  end

  def prerequisite_message(context_module)
    f(prerequisite_message_selector(context_module))
  end

  def remove_prerequisite_button
    fxpath(remove_prerequisite_button_selector)
  end

  def settings_panel
    f(settings_panel_selector)
  end

  def settings_tab
    f(settings_tab_selector)
  end

  def settings_tray_cancel_button
    fxpath(settings_tray_cancel_button_selector)
  end

  def settings_tray_close_button
    fxpath(settings_tray_close_button_selector)
  end

  def settings_tray_update_module_button
    fxpath(settings_tray_update_module_button_selector)
  end

  #------------------------------ Actions ------------------------------

  def add_prerequisites_button_exists?
    element_exists?(add_prerequisites_button_selector, true)
  end

  def click_add_prerequisites_button
    add_prerequisites_button.click
  end

  def click_assign_to_tab
    assign_to_tab.click
  end

  def click_clear_all
    clear_all.click
  end

  def click_custom_access_radio
    custom_access_radio_click.click
  end

  def click_everyone_radio
    everyone_radio_click.click
  end

  def click_remove_prerequisite_button
    remove_prerequisite_button.click
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

  def settings_tray_exists?
    element_exists?(module_settings_tray_selector)
  end
end
