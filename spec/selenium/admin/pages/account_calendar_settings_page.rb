# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module AccountCalendarSettingsPage
  # ---------------------- Selectors ----------------------

  def account_calendar_navigation_selector
    ".account_calendars"
  end

  def account_checkboxes_selector(account_folder_name, number_of_subitems)
    "[aria-label = '#{account_folder_name} (#{number_of_subitems})'] [data-testid = 'flex-calendar-item'] label"
  end

  def account_folder_selector(account_name, number_of_subitems)
    "[aria-label = '#{account_name} (#{number_of_subitems})'] button"
  end

  def apply_changes_button_selector
    "[data-testid='save-button']"
  end

  def calendars_selected_text_selector
    "[data-testid='calendars-selected-text']"
  end
  # ---------------------- Elements ----------------------

  def account_calendar_navigation
    f(account_calendar_navigation_selector)
  end

  def account_checkboxes(account_folder_name, number_of_subitems)
    ff(account_checkboxes_selector(account_folder_name, number_of_subitems))
  end

  def account_folder(account_name, number_of_items)
    f(account_folder_selector(account_name, number_of_items))
  end

  def apply_changes_button
    f(apply_changes_button_selector)
  end

  def calendars_selected_text
    f(calendars_selected_text_selector)
  end

  # ---------------------- Actions -----------------------

  def account_checked?(checkbox_selector)
    is_checked(checkbox_selector)
  end

  def click_account_calendar_navigation
    account_calendar_navigation.click
  end

  def click_account_checkbox(checkbox_element)
    checkbox_element.click
  end

  def click_account_folder(account_name, number_of_subfolders)
    account_folder(account_name, number_of_subfolders).click
  end

  def click_apply_changes_button
    apply_changes_button.click
  end

  # ---------------------- Methods -----------------------
end
