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

require_relative "../common"

module ItemsAssignToTray
  #------------------------------ Selectors -----------------------------
  def add_assign_to_card_selector
    "[data-testid='add-card']"
  end

  def assign_to_button_selector(button_title)
    "button[title='#{button_title}']"
  end

  def assign_to_card_delete_button_selector
    "//*[@data-testid = 'delete-card-button']"
  end

  def assign_to_date_and_time_selector
    "[data-testid='clearable-date-time-input']"
  end

  def assign_to_date_selector
    "//*[@data-testid = 'clearable-date-time-input']//*[contains(@class,'-dateInput')]//input"
  end

  def available_from_input_selector
    "[data-testid = 'unlock_at_input']"
  end

  def clear_due_datetime_selector
    "//button[*//*[contains(text(),'Clear due date/time')]]"
  end

  def close_button_selector
    "//*[@data-testid = 'module-item-edit-tray']//button[. = 'Close']"
  end

  def due_date_input_selector
    "[data-testid = 'due_at_input']"
  end

  def reply_to_topic_due_date_input_selector
    "[data-testid = 'reply_to_topic_due_at_input']"
  end

  def required_replies_due_date_input_selector
    "[data-testid = 'required_replies_due_at_input']"
  end

  def assignee_selected_option_selector
    "[data-testid='assignee_selector_selected_option']"
  end

  def assign_to_in_tray_selector(button_title)
    "#{module_item_assign_to_card_selector} #{assign_to_button_selector(button_title)}"
  end

  def assign_to_option_selector(assignee)
    "//li[.//*[contains(text(), '#{assignee}')]]"
  end

  def assign_to_time_selector
    "//*[@data-testid = 'clearable-date-time-input']//*[contains(@class, '-select')]//input"
  end

  def bp_locked_alert_text_selector(alert_text = "Due Dates & Availability Dates")
    "//*[. = '#{alert_text}']"
  end

  def cancel_button_selector
    "//*[@data-testid = 'module-item-edit-tray']//button[.//*[contains(text(), 'Cancel')]]"
  end

  def highlighted_card_selector
    "[data-testid='highlighted_card']"
  end

  def icon_type_selector(icon_type)
    "[name='Icon#{icon_type}']"
  end

  def inherited_from_selector
    "#{module_item_assign_to_card_selector} [data-testid='context-module-text']"
  end

  def item_type_text_selector
    "[data-testid='item-type-text']"
  end

  def loading_spinner_selector
    "[data-testid='module-item-edit-tray'] [title='Loading']"
  end

  def module_item_assignee_selector
    "#{module_item_assign_to_card_selector} [data-testid='assignee_selector']"
  end

  def module_item_assign_to_card_selector
    "[data-testid='item-assign-to-card']"
  end

  def module_item_edit_tray_selector
    "[data-testid='module-item-edit-tray']"
  end

  def save_button_selector(save_button_text = "Save")
    "//*[@data-testid = 'module-item-edit-tray-footer']//button[.//*[contains(text(), '#{save_button_text}')]]"
  end

  def selected_assignee_options_text(card)
    card.find_all(assignee_selected_option_selector).map(&:text)
  end

  def convert_override_alert_selector
    "[data-testid='differentiation-tag-converter-message']"
  end

  def convert_override_button_selector
    "[data-testid='convert-differentiation-tags-button']"
  end

  def tray_header_selector
    "[data-testid='module-item-edit-tray'] h2"
  end

  def until_input_selector
    "[data-testid = 'lock_at_input']"
  end

  def reply_to_topic_datetime_selector
    "[data-testid='reply_to_topic_due_at_input'] input[type='text']"
  end

  def required_replies_datetime_selector
    "[data-testid='required_replies_due_at_input'] input[type='text']"
  end

  def available_from_datetime_selector
    "[data-testid='unlock_at_input'] input[type='text']"
  end

  def until_datetime_selector
    "[data-testid='lock_at_input'] input[type='text']"
  end

  #------------------------------ Elements ------------------------------
  def add_assign_to_card
    ff(add_assign_to_card_selector)
  end

  def assign_to_card_delete_button
    ffxpath(assign_to_card_delete_button_selector)
  end

  def assign_to_date
    ffxpath(assign_to_date_selector)
  end

  def assign_to_date_and_time
    ff(assign_to_date_and_time_selector)
  end

  def all_displayed_assign_to_date_and_time
    ff(assign_to_date_and_time_selector + " input")
      .map { |input| input.attribute("value") }
      .each_slice(2)
      .map { |date, time| Time.zone.parse("#{date} #{time}") }
  end

  def assign_to_reply_to_topic_date(card_number = 0)
    position = 0
    number_of_fields = 4
    assign_to_date[position + (card_number * number_of_fields)]
  end

  def assign_to_reply_to_topic_time(card_number = 0)
    position = 0
    number_of_fields = 4
    assign_to_time[position + (card_number * number_of_fields)]
  end

  def assign_to_required_replies_date(card_number = 0)
    position = 1
    number_of_fields = 4
    assign_to_date[position + (card_number * number_of_fields)]
  end

  def assign_to_required_replies_time(card_number = 0)
    position = 1
    number_of_fields = 4
    assign_to_time[position + (card_number * number_of_fields)]
  end

  def assign_to_available_from_date(card_number = 0, exclude_due_date = false, exclude_checkpoints = true)
    position = exclude_due_date ? 0 : 1
    position = 2 unless exclude_checkpoints
    number_of_fields = exclude_due_date ? 2 : 3
    unless exclude_checkpoints
      position = 2
      number_of_fields = 4
    end
    assign_to_date[position + (card_number * number_of_fields)]
  end

  def assign_to_available_from_time(card_number = 0, exclude_due_date = false, exclude_checkpoints = true)
    position = exclude_due_date ? 0 : 1
    number_of_fields = exclude_due_date ? 2 : 3
    unless exclude_checkpoints
      position = 2
      number_of_fields = 4
    end
    assign_to_time[position + (card_number * number_of_fields)]
  end

  def assign_to_due_date(card_number = 0)
    assign_to_date[0 + (card_number * 3)]
  end

  def assign_to_due_time(card_number = 0)
    assign_to_time[0 + (card_number * 3)]
  end

  def assign_to_in_tray(button_title)
    ff(assign_to_in_tray_selector(button_title))
  end

  def assign_to_time
    ffxpath(assign_to_time_selector)
  end

  def assign_to_until_date(card_number = 0, exclude_due_date = false, exclude_checkpoints = true)
    position = exclude_due_date ? 1 : 2
    number_of_fields = exclude_due_date ? 2 : 3
    unless exclude_checkpoints
      position = 3
      number_of_fields = 4
    end
    assign_to_date[position + (card_number * number_of_fields)]
  end

  def assign_to_until_time(card_number = 0, exclude_due_date = false, exclude_checkpoints = true)
    position = exclude_due_date ? 1 : 2
    number_of_fields = exclude_due_date ? 2 : 3
    unless exclude_checkpoints
      position = 3
      number_of_fields = 4
    end
    assign_to_time[position + (card_number * number_of_fields)]
  end

  def bp_locked_alert_text
    fxpath(bp_locked_alert_text_selector)
  end

  def cancel_button
    fxpath(cancel_button_selector)
  end

  def clear_due_datetime
    ffxpath(clear_due_datetime_selector)
  end

  def close_button
    fxpath(close_button_selector)
  end

  def highlighted_item_assign_to_card
    ff(highlighted_card_selector)
  end

  def icon_type(icon_type)
    f(icon_type_selector(icon_type))
  end

  def inherited_from
    ff(inherited_from_selector)
  end

  def item_type_text
    f(item_type_text_selector)
  end

  def loading_spinner
    fj(loading_spinner_selector)
  end

  def module_item_assign_to_card
    ff(module_item_assign_to_card_selector)
  end

  def module_item_assignee
    ff(module_item_assignee_selector)
  end

  def module_item_edit_tray
    f(module_item_edit_tray_selector)
  end

  def save_button(save_button_text = "Save")
    fxpath(save_button_selector(save_button_text))
  end

  def selected_assignee_options
    ff(assignee_selected_option_selector)
  end

  def tray_header
    f(tray_header_selector)
  end

  def reply_to_topic_datetime_inputs
    ff(reply_to_topic_datetime_selector)
  end

  def required_replies_datetime_inputs
    ff(required_replies_datetime_selector)
  end

  def available_from_datetime_inputs
    ff(available_from_datetime_selector)
  end

  def until_datetime_inputs
    ff(until_datetime_selector)
  end

  #------------------------------ Actions ------------------------------

  def click_add_assign_to_card(button_number = 0)
    add_assign_to_card[button_number].click
  end

  def click_duedate_clear_button(card_number = 0)
    clear_due_datetime[card_number].click
  end

  def click_delete_assign_to_card(card_number)
    assign_to_card_delete_button[card_number].click
  end

  def click_delete_assign_to_item(item_title, item_number = 0)
    assign_to_in_tray(item_title)[item_number].click
  end

  def click_cancel_button
    cancel_button.click
  end

  def click_save_button(save_button_text = "Save")
    save_button(save_button_text).click
  end

  def icon_type_exists?(icon_type)
    element_exists?(icon_type_selector(icon_type))
  end

  def item_tray_exists?
    element_exists?(module_item_edit_tray_selector)
  end

  def select_module_item_assignee(card_number, assignee)
    # module_item_assignee[card_number].click
    click_option(module_item_assignee[card_number], assignee)
  end

  def update_due_date(card_number, due_date)
    replace_content(assign_to_due_date(card_number), due_date, tab_out: true)
  end

  def update_due_time(card_number, due_time)
    replace_content(assign_to_due_time(card_number), due_time, tab_out: true)
  end

  def update_reply_to_topic_date(card_number, due_date)
    replace_content(assign_to_reply_to_topic_date(card_number), due_date, tab_out: true)
  end

  def update_reply_to_topic_time(card_number, due_time)
    replace_content(assign_to_reply_to_topic_time(card_number), due_time, tab_out: true)
  end

  def update_required_replies_date(card_number, due_date)
    replace_content(assign_to_required_replies_date(card_number), due_date, tab_out: true)
  end

  def update_required_replies_time(card_number, due_time)
    replace_content(assign_to_required_replies_time(card_number), due_time, tab_out: true)
  end

  def update_available_date(card_number, available_date, exclude_due_date = false, exclude_checkpoints = true)
    replace_content(assign_to_available_from_date(card_number, exclude_due_date, exclude_checkpoints), available_date, tab_out: true)
  end

  def update_available_time(card_number, available_time, exclude_due_date = false, exclude_checkpoints = true)
    replace_content(assign_to_available_from_time(card_number, exclude_due_date, exclude_checkpoints), available_time, tab_out: true)
  end

  def update_until_date(card_number, until_date, exclude_due_date = false, exclude_checkpoints = true)
    replace_content(assign_to_until_date(card_number, exclude_due_date, exclude_checkpoints), until_date, tab_out: true)
  end

  def update_until_time(card_number, until_time, exclude_due_date = false, exclude_checkpoints = true)
    replace_content(assign_to_until_time(card_number, exclude_due_date, exclude_checkpoints), until_time, tab_out: true)
  end

  def wait_for_assign_to_tray_spinner
    begin
      keep_trying_until { (element_exists?(loading_spinner_selector) == false) }
    rescue Selenium::WebDriver::Error::TimeoutError
      # ignore - sometimes spinner doesn't appear in Chrome
    end
    wait_for_ajaximations
  end

  def combine_date_and_time(date_input, time_input)
    date = date_input.attribute("value")
    time = time_input.attribute("value")
    return "" if date.empty? && time.empty?

    "#{date} #{time}".strip
  end

  def get_reply_to_topic_datetime(card_index)
    combine_date_and_time(reply_to_topic_datetime_inputs[card_index * 2], reply_to_topic_datetime_inputs[(card_index * 2) + 1])
  end

  def get_required_replies_datetime(card_index)
    combine_date_and_time(required_replies_datetime_inputs[card_index * 2], required_replies_datetime_inputs[(card_index * 2) + 1])
  end

  def get_available_from_datetime(card_index)
    combine_date_and_time(available_from_datetime_inputs[card_index * 2], available_from_datetime_inputs[(card_index * 2) + 1])
  end

  def get_until_datetime(card_index)
    combine_date_and_time(until_datetime_inputs[card_index * 2], until_datetime_inputs[(card_index * 2) + 1])
  end

  def get_all_dates_for_card(card_index)
    {
      reply_to_topic: get_reply_to_topic_datetime(card_index),
      required_replies: get_required_replies_datetime(card_index),
      available_from: get_available_from_datetime(card_index),
      until: get_until_datetime(card_index)
    }
  end

  def get_all_dates_for_all_cards
    card_count = [
      reply_to_topic_datetime_inputs.length,
      required_replies_datetime_inputs.length,
      available_from_datetime_inputs.length,
      until_datetime_inputs.length
    ].max / 2 # Divide by 2 because we have separate inputs for date and time

    (0...card_count).map do |card_index|
      get_all_dates_for_card(card_index)
    end
  end
end
