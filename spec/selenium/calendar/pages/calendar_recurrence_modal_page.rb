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

module CalendarRecurrenceModelPage
  #------------------------- Selectors --------------------------
  def cancel_button_selector
    "//*[@aria-label='Custom Repeating Event']//button[.//*[. = 'Cancel']]"
  end

  def custom_recurrence_modal_selector
    "[aria-label='Custom Repeating Event']"
  end

  def done_button_selector
    "//*[@aria-label='Custom Repeating Event']//button[.//*[. = 'Done']]"
  end

  def repeat_frequency_selector
    "[data-testid='repeat-frequency']"
  end

  #------------------------- Elements ---------------------------
  def cancel_button
    fxpath(cancel_button_selector)
  end

  def custom_recurrence_modal
    f(custom_recurrence_modal_selector)
  end

  def done_button
    fxpath(done_button_selector)
  end

  def repeat_frequency
    f(repeat_frequency_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def click_cancel_button
    cancel_button.click
  end

  def click_done_button
    done_button.click
  end

  def recurrence_modal_exists?
    element_exists?(custom_recurrence_modal_selector)
  end

  def repeat_frequency_picker_value
    element_value_for_attr(repeat_frequency, "value")
  end

  def select_repeat_frequency(frequency)
    click_option(repeat_frequency_selector, frequency)
  end
end
