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
  def create_new_event_btn_selector
    "#create_new_event_link"
  end

  def delete_confirm_button_selector
    "//*[@aria-label='Confirm Deletion']//button[.//*[. = 'Delete']]"
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

  def events_in_month_view_selector
    ".fc-event"
  end

  def frequency_picker_selector
    "[data-testid='frequency-picker']"
  end

  def submit_button_selector
    "[data-testid='edit-calendar-event-submit-button']"
  end

  def use_section_dates_checkbox_selector
    "#use_section_dates"
  end

  #------------------------- Elements ---------------------------
  def all_events_in_month_view
    ff(events_in_month_view_selector)
  end

  def create_new_event_btn
    f(create_new_event_btn_selector)
  end

  def delete_confirm_button
    fxpath(delete_confirm_button_selector)
  end

  def edit_event_date_input
    f(edit_event_date_input_selector)
  end

  def edit_event_title_input
    f(edit_event_title_input_selector)
  end

  def edit_event_modal_submit_btn
    f(edit_event_modal_submit_btn_selector)
  end

  def frequency_picker
    f(frequency_picker_selector)
  end

  def submit_button
    f(submit_button_selector)
  end

  def use_section_dates_checkbox
    f(use_section_dates_checkbox_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def add_calendar_event_title(title_text)
    replace_content(edit_event_title_input, title_text)
  end

  def click_delete_confirm_button
    delete_confirm_button.click
  end

  def click_submit_button
    submit_button.click
    wait_for_ajaximations
  end

  def create_new_calendar_event
    create_new_event_btn.click
    wait_for_ajaximations
  end

  def enter_new_event_date(date_text)
    replace_content(edit_event_date_input, date_text)
    edit_event_date_input.send_keys(:enter)
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
end
