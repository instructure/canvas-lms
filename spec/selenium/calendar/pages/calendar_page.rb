# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module CalendarPage
  #------------------------- Selectors --------------------------
  def agenda_events_selector(event_title)
    "//*[@class='agenda-event__item']//*[contains(@class, 'agenda-event__title') and contains(text(),'#{event_title}')]"
  end

  def calendar_content_selector
    "#content"
  end

  def close_edit_button_selector
    "//*[@aria-label='Confirm Changes']//button[.//*[. = 'Close']]"
  end

  def create_new_event_btn_selector
    "#create_new_event_link"
  end

  def delete_event_link_selector
    ".delete_event_link"
  end

  def edit_confirm_modal_selector
    "[aria-label='Confirm Changes']"
  end

  def delete_confirm_button_selector
    "//*[@aria-label='Confirm Deletion']//button[.//*[. = 'Delete']]"
  end

  def edit_confirm_button_selector
    "//*[@aria-label='Confirm Changes']//button[.//*[. = 'Confirm']]"
  end

  def edit_event_button_selector
    "//button[. = 'Edit']"
  end

  def edit_event_rule_text_selector
    ".event-details-timestring"
  end

  def edit_event_modal_selector
    "[data-testid='calendar-event-form']"
  end

  def edit_event_title_input_selector
    "#edit_calendar_event_form #calendar_event_title"
  end

  def edit_event_date_input_selector
    "[data-testid='edit-calendar-event-form-date']"
  end

  def edit_event_modal_submit_btn_selector
    "#edit_calendar_event_form button.event_button"
  end

  def event_title_input_selector
    "[data-testid='calendar-event-form'] [placeholder='Input Event Title...']"
  end

  def events_in_a_series_selector(event_title)
    "#content .fc-event:visible:contains('#{event_title}')"
  end

  def updated_events_in_a_series_selector
    "#content .fc-event:visible:contains('event updated in a series')"
  end

  def events_in_month_view_selector
    ".fc-event"
  end

  def frequency_picker_selector
    "[data-testid='frequency-picker']"
  end

  def more_options_button_selector
    "[data-testid='edit-calendar-event-more-options-button']"
  end

  def submit_button_selector
    "[data-testid='edit-calendar-event-submit-button']"
  end

  def use_section_dates_checkbox_selector
    "#use_section_dates"
  end

  def this_event_radio_button_selector
    "//*[@aria-label='Confirm Changes']//label[../input[@value = 'one']]"
  end

  def all_events_radio_button_selector
    "//*[@aria-label='Confirm Changes']//label[../input[@value = 'all']]"
  end

  def this_and_following_event_radio_button_selector
    "//*[@aria-label='Confirm Changes']//label[../input[@value = 'following']]"
  end

  def event_calendar_selector_input_selector
    "[data-testid='edit-calendar-event-form-context']"
  end

  def event_details_modal_selector
    ".event-details"
  end

  def event_details_modal_close_button_selector
    ".event-details .popover_close"
  end

  def screenreader_message_holder_selector
    "#flash_screenreader_holder"
  end

  #------------------------- Elements ---------------------------

  def agenda_events(event_title)
    ffxpath(agenda_events_selector(event_title))
  end

  def all_events_in_month_view
    ff(events_in_month_view_selector)
  end

  def calendar_content
    f(calendar_content_selector)
  end

  def close_edit_button
    fxpath(close_edit_button_selector)
  end

  def create_new_event_btn
    f(create_new_event_btn_selector)
  end

  def delete_confirm_button
    fxpath(delete_confirm_button_selector)
  end

  def edit_confirm_button
    fxpath(edit_confirm_button_selector)
  end

  def edit_confirm_modal
    f(edit_confirm_modal_selector)
  end

  def edit_event_button
    fxpath(edit_event_button_selector)
  end

  def edit_event_date_input
    f(edit_event_date_input_selector)
  end

  def edit_event_modal
    f(edit_event_modal_selector)
  end

  def edit_event_rule_text
    f(edit_event_rule_text_selector)
  end

  def edit_event_title_input
    f(edit_event_title_input_selector)
  end

  def edit_event_modal_submit_btn
    f(edit_event_modal_submit_btn_selector)
  end

  def event_title_input
    f(event_title_input_selector)
  end

  def events_in_a_series(event_title)
    ffj(events_in_a_series_selector(event_title))
  end

  def frequency_picker
    f(frequency_picker_selector)
  end

  def more_options_button
    f(more_options_button_selector)
  end

  def submit_button
    f(submit_button_selector)
  end

  def use_section_dates_checkbox
    f(use_section_dates_checkbox_selector)
  end

  def event_calendar_selector_input
    f(event_calendar_selector_input_selector)
  end

  def event_details_modal
    f(event_details_modal_selector)
  end

  def event_details_modal_close_button
    f(event_details_modal_close_button_selector)
  end

  def screenreader_message_holder
    f(screenreader_message_holder_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def add_calendar_event_title(title_text)
    replace_content(edit_event_title_input, title_text)
  end

  def click_close_edit_button
    close_edit_button.click
  end

  def click_edit_confirm_button
    edit_confirm_button.click
  end

  def click_edit_event_button
    edit_event_button.click
  end

  def click_delete_confirm_button
    delete_confirm_button.click
  end

  def click_more_options_button
    more_options_button.click
  end

  def click_submit_button
    submit_button.click
    wait_for_ajaximations
  end

  def create_new_calendar_event
    create_new_event_btn.click
    wait_for_ajaximations
  end

  def edit_event_modal_exists?
    element_exists?(edit_event_modal_selector)
  end

  def enter_new_event_date(date_text)
    replace_content(edit_event_date_input, date_text)
    edit_event_date_input.send_keys(:enter)
  end

  def enter_event_title(title_text)
    replace_content(event_title_input, title_text)
    event_title_input.send_keys(:tab)
  end

  def frequency_picker_value
    element_value_for_attr(frequency_picker, "value")
  end

  def select_frequency_option(option_text)
    click_option(frequency_picker_selector, option_text)
  end

  def submit_calendar_event_changes
    edit_event_modal_submit_btn.click
    wait_for_ajaximations
  end

  def select_event_calendar(calendar_text)
    click_option(event_calendar_selector_input, calendar_text)
  end

  def click_event_details_modal_close_button
    event_details_modal_close_button.click
  end
end
