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

module CalendarEditPage
  #------------------------- Selectors --------------------------

  def calendar_event_title_selector
    "#calendar_event_title"
  end

  def calendar_rce_selector
    ".ic-RichContentEditor"
  end

  def calendar_start_date_selector
    "[name='start_date']"
  end

  def create_event_button_selector
    "//button[contains(text() ,'Create Event')]"
  end

  def rce_iframe_selector
    "iframe"
  end

  def update_cancel_button_selector
    "//*[@role = 'button' and contains(text() ,'Cancel')]"
  end

  def update_event_button_selector
    "//button[contains(text() ,'Update Event')]"
  end

  #------------------------- Elements ---------------------------

  def calendar_event_title
    f(calendar_event_title_selector)
  end

  def calendar_rce
    f(calendar_rce_selector)
  end

  def calendar_start_date
    f(calendar_start_date_selector)
  end

  def create_event_button
    fxpath(create_event_button_selector)
  end

  def rce_iframe
    f(rce_iframe_selector)
  end

  def update_cancel_button
    fxpath(update_cancel_button_selector)
  end

  def update_event_button
    fxpath(update_event_button_selector)
  end

  #----------------------- Actions/Methods ----------------------

  def enter_calendar_event_title(title)
    calendar_start_date.send_keys([:control, "a"], :backspace)
    replace_content(calendar_event_title, title, tab_out: true)
  end

  def enter_calendar_start_date(date)
    calendar_start_date.send_keys([:control, "a"], :backspace)
    replace_content(calendar_start_date, date, tab_out: true)
  end

  def click_update_cancel_button
    update_cancel_button.click
  end

  def click_create_event_button
    create_event_button.click
  end

  def click_update_event_button
    update_event_button.click
  end

  def wait_for_calendar_rce
    wait_for_tiny(f(rce_iframe_selector, f(calendar_rce_selector)))
  end
end
