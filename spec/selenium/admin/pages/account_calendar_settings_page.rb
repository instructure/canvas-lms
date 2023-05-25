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

  def account_checkboxes_selector(account_id)
    "[data-testid='toggle-group-#{account_id}'] label"
  end

  def account_folder_selector(account_id)
    "[data-testid='toggle-group-#{account_id}'] > span:first-child button"
  end

  def apply_changes_button_selector
    "[data-testid='save-button']"
  end

  def auto_subscribe_confirm_button_selector
    "[data-testid='confirm-button']"
  end

  def auto_subscribe_cancel_button_selector
    "[data-testid='close-button']"
  end

  def auto_subscribe_x_close_button_selector
    "[data-testid='x-close-button']"
  end

  def auto_subscribe_confirm_modal_selector
    "[aria-label='Apply Changes']"
  end

  def auto_subscription_dropdown_selector
    "[data-testid='subscription-dropdown']"
  end

  def calendar_search_selector
    "[placeholder='Search Calendars']"
  end

  def calendars_selected_text_selector
    "[data-testid='calendars-selected-text']"
  end

  def calendar_search_list_selector
    "[data-testid = 'flex-calendar-item']:visible"
  end

  def visible_account_calendar_text_selector
    "[data-testid = 'account-calendar-name']:visible"
  end

  def filter_dropdown_selector
    "[data-testid = 'account-filter-dropdown']"
  end

  def search_empty_image_selector
    "[data-testid='empty-account-search']"
  end
  # ---------------------- Elements ----------------------

  def account_calendar_navigation
    f(account_calendar_navigation_selector)
  end

  def account_checkboxes(account_id)
    ff(account_checkboxes_selector(account_id))
  end

  def account_folder(account_id)
    f(account_folder_selector(account_id))
  end

  def apply_changes_button
    f(apply_changes_button_selector)
  end

  def auto_subscribe_confirm_button
    f(auto_subscribe_confirm_button_selector)
  end

  def auto_subscribe_cancel_button
    f(auto_subscribe_cancel_button_selector)
  end

  def auto_subscribe_x_close_button
    f(auto_subscribe_x_close_button_selector)
  end

  def auto_subscribe_confirm_modal
    f(auto_subscribe_confirm_modal_selector)
  end

  def auto_subscription_dropdowns
    ff(auto_subscription_dropdown_selector)
  end

  def calendar_search
    f(calendar_search_selector)
  end

  def calendar_search_list
    ffj(calendar_search_list_selector)
  end

  def calendars_selected_text
    f(calendars_selected_text_selector)
  end

  def visible_account_calendar_text
    ffj(visible_account_calendar_text_selector)
  end

  def filter_dropdown
    f(filter_dropdown_selector)
  end

  def search_empty_image
    f(search_empty_image_selector)
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

  def click_account_folder(account_id)
    account_folder(account_id).click
  end

  def click_apply_changes_button
    apply_changes_button.click
  end

  def click_auto_subscribe_confirm_button
    auto_subscribe_confirm_button.click
  end

  def click_auto_subscribe_cancel_button
    auto_subscribe_cancel_button.click
  end

  def click_auto_subscribe_x_close_button
    auto_subscribe_x_close_button.click
  end

  def input_search_string(search_string)
    driver.action.send_keys(calendar_search, search_string).perform
    driver.action.send_keys(calendar_search, :tab).perform
    driver.action.send_keys(calendar_search, :tab).perform
  end

  # ---------------------- Methods -----------------------
end
