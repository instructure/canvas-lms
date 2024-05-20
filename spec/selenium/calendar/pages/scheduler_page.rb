# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module SchedulerPage
  #------------------------- Selectors --------------------------
  def message_students_button_selector
    'button:contains("Message Students")'
  end

  def message_body_textarea_selector
    "textarea[name='body']"
  end

  def send_message_button_selector
    'button:contains("Send")'
  end

  def save_button_selector
    '.EditPage__Header button:contains("Save")'
  end

  def location_input_selector
    'input[name="location"]'
  end

  #------------------------- Elements ---------------------------
  def message_students_button
    fj(message_students_button_selector)
  end

  def message_body_textarea
    f(message_body_textarea_selector)
  end

  def send_message_button
    fj(send_message_button_selector)
  end

  def save_button
    fj(save_button_selector)
  end

  def location_input
    f(location_input_selector)
  end

  #----------------------- Actions/Methods ----------------------
  def click_message_students_button
    message_students_button.click
  end

  def click_send_message_button
    send_message_button.click
  end

  def click_save_button
    save_button.click
  end
end
