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

module CalendarRecurrenceModalPage
  #------------------------- Selectors --------------------------
  def after_radio_button_selector
    "//*[@aria-label='Custom Repeating Event']//label[../input[@value = 'AFTER']]"
  end

  def cancel_button_selector
    "//*[@aria-label='Custom Repeating Event']//button[.//*[. = 'Cancel']]"
  end

  def custom_recurrence_modal_selector
    "[aria-label='Custom Repeating Event']"
  end

  def day_of_week_input_selector(day)
    "##{day}"
  end

  def day_of_week_label_selector(day)
    "//label[*//input[@id = '#{day}']]"
  end

  def done_button_selector
    "//*[@aria-label='Custom Repeating Event']//button[.//*[. = 'Done']]"
  end

  def on_radio_button_selector
    "//*[@aria-label='Custom Repeating Event']//label[../input[@value = 'ON']]"
  end

  def recurrence_end_count_input_selector
    "[data-testid='recurrence-end-count-input']"
  end

  def recurrence_end_date_selector
    "[data-testid='recurrence-ends-on-input']"
  end

  def repeat_month_mode_selector
    "[data-testid='repeat-month-mode']"
  end

  def repeat_frequency_selector
    "[data-testid='repeat-frequency']"
  end

  def repeat_interval_selector
    "[data-testid='repeat-interval']"
  end

  def custom_recurrence_selector
    "[data-testid='custom-recurrence']"
  end

  #------------------------- Elements ---------------------------

  def after_radio_button
    fxpath(after_radio_button_selector)
  end

  def cancel_button
    fxpath(cancel_button_selector)
  end

  def custom_recurrence_modal
    f(custom_recurrence_modal_selector)
  end

  def day_selection_checkbox(day)
    fxpath(day_of_week_label_selector(day))
  end

  def day_of_week_input(day)
    f(day_of_week_input_selector(day))
  end

  def done_button
    fxpath(done_button_selector)
  end

  def on_radio_button
    fxpath(on_radio_button_selector)
  end

  def recurrence_end_count_input
    f(recurrence_end_count_input_selector)
  end

  def recurrence_end_date
    f(recurrence_end_date_selector)
  end

  def repeat_month_mode
    f(repeat_month_mode_selector)
  end

  def repeat_frequency
    f(repeat_frequency_selector)
  end

  def repeat_interval
    f(repeat_interval_selector)
  end

  def custom_recurrence
    f(custom_recurrence_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def click_after_radio_button
    after_radio_button.click
  end

  def click_cancel_button
    cancel_button.click
  end

  def click_day_selection_checkbox(day)
    day_selection_checkbox(day).click
  end

  def click_done_button
    done_button.click
  end

  def click_on_radio_button
    on_radio_button.click
  end

  def enter_recurrence_end_date(date)
    recurrence_end_date.send_keys([:control, "a"], :backspace)
    replace_content(recurrence_end_date, date, tab_out: true)
  end

  def enter_repeat_interval(interval)
    repeat_interval.send_keys([:control, "a"], :backspace)
    replace_content(repeat_interval, interval, tab_out: true)
  end

  def enter_recurrence_end_count(end_count)
    recurrence_end_count_input.send_keys([:control, "a"], :backspace)
    replace_content(recurrence_end_count_input, end_count, tab_out: true)
  end

  def recurrence_modal_exists?
    element_exists?(custom_recurrence_modal_selector)
  end

  def repeat_frequency_picker_value
    element_value_for_attr(repeat_frequency, "value")
  end

  def repeat_interval_value
    element_value_for_attr(repeat_interval, "value")
  end

  def recurrence_end_count_value
    element_value_for_attr(recurrence_end_count_input, "value")
  end

  def select_repeat_month_mode(mode)
    click_option(repeat_month_mode_selector, mode)
  end

  def select_repeat_frequency(frequency)
    click_option(repeat_frequency_selector, frequency)
  end

  delegate :text, to: :custom_recurrence, prefix: true
end
