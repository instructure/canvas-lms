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

module CalendarOtherCalendarsPage
  #------------------------- Selectors --------------------------
  def open_other_calendars_modal_btn_selector
    "button[data-testid='add-other-calendars-button']"
  end

  def other_calendars_container_selector
    "#other-calendars-list-holder"
  end

  def other_calendars_context_selector
    "#other-calendars-context-list > .context_list_context"
  end

  def sidebar_selector
    "#right-side-wrapper"
  end

  def modal_cancel_btn_selector
    "button[data-testid='footer-close-button']"
  end

  def modal_save_btn_selector
    "button[data-testid='save-calendars-button']"
  end

  def delete_calendar_btn_selector
    "#other-calendars-context-list > .context_list_context > .buttons-wrapper > .ContextList__DeleteBtn"
  end

  def modal_empty_state_selector
    ".accounts-empty-state"
  end

  def context_list_item_selector(context_id)
    "#other-calendars-context-list > li[data-context=account_#{context_id}]"
  end

  def create_new_event_link_selector
    "#create_new_event_link"
  end

  def flash_alert_selector
    ".flashalert-message"
  end

  def calendar_event_selector
    ".fc-event"
  end

  def calendar_body_selector
    ".fc-body"
  end

  def search_input_selector
    "input[data-testid='search-input']"
  end

  def account_calendar_checkbox_selector(context_id)
    "input[data-testid=account-#{context_id}-checkbox]"
  end

  def account_calendars_list_selector
    "ul[data-testid='account-calendars-list']"
  end

  def account_calendar_list_items_selector
    "#{account_calendars_list_selector} > li"
  end

  def account_calendar_available_list_item_selector
    "#other-calendars-context-list .context_list_context .context-list-toggle-box"
  end

  def event_popover_header_selector
    ".event-details-header"
  end

  def event_popover_content_selector
    ".event-details-content"
  end

  def event_popover_selector
    ".event-details"
  end

  def event_link_selector
    ".view_event_link"
  end

  def other_calendars_new_pill_selector
    "#other-calendars-list-holder .new-feature-pill"
  end

  #------------------------- Elements ---------------------------
  def open_other_calendars_modal_btn
    f(open_other_calendars_modal_btn_selector)
  end

  def other_calendars_container
    f(other_calendars_container_selector)
  end

  def other_calendars_context
    ff(other_calendars_context_selector)
  end

  def other_calendars_context_labels
    ff("#{other_calendars_context_selector} > label")
  end

  def sidebar
    f(sidebar_selector)
  end

  def modal_cancel_btn
    f(modal_cancel_btn_selector)
  end

  def modal_save_btn
    f(modal_save_btn_selector)
  end

  def delete_calendar_btn
    ff(delete_calendar_btn_selector)
  end

  def modal_empty_state
    f(modal_empty_state_selector)
  end

  def create_new_event_link
    f(create_new_event_link_selector)
  end

  def flash_alert
    f(flash_alert_selector)
  end

  def calendar_body
    f(calendar_body_selector)
  end

  def search_input
    f(search_input_selector)
  end

  def account_calendar_checkbox(context_id)
    f(account_calendar_checkbox_selector(context_id))
  end

  def account_calendars_list
    f(account_calendars_list_selector)
  end

  def account_calendar_list_items
    ffj(account_calendar_list_items_selector)
  end

  def account_calendar_available_list_item
    f(account_calendar_available_list_item_selector)
  end

  def event_popover_title
    f(event_popover_header_selector)
  end

  def event_popover_content
    f(event_popover_content_selector)
  end

  def event_popover
    f(event_popover_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def open_other_calendars_modal
    open_other_calendars_modal_btn.click
    wait_for_ajaximations
  end

  def click_modal_cancel_btn
    modal_cancel_btn.click
    wait_for_ajaximations
  end

  def click_modal_save_btn
    modal_save_btn.click
    wait_for_ajaximations
  end

  def select_other_calendar(context_id)
    f("input[data-testid='account-#{context_id}-checkbox']")
    label_element = driver.find_element(:css, "input[data-testid='account-#{context_id}-checkbox'] + label")
    label_element.click
  end

  def open_create_new_event_modal
    create_new_event_link.click
  end

  def close_flash_alert
    f("#{flash_alert_selector} button").click
  end

  def search_account(search_term)
    driver.action.send_keys(search_input, search_term).perform
    driver.action.send_keys(search_input, :tab).perform
    driver.action.send_keys(search_input, :tab).perform
    wait_for_ajax_requests
  end
end
