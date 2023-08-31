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
  def assign_to_panel_selector
    "[data-testid='assign-to-panel']"
  end

  def assign_to_tab_selector
    "#tab-assign-to"
  end

  def module_settings_tray_selector
    "[aria-label='Edit Module Settings']"
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

  def assign_to_panel
    f(assign_to_panel_selector)
  end

  def assign_to_tab
    f(assign_to_tab_selector)
  end

  def module_settings_tray
    f(module_settings_tray_selector)
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

  def click_assign_to_tab
    assign_to_tab.click
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

  def settings_tray_exists?
    element_exists?(module_settings_tray_selector)
  end
end
