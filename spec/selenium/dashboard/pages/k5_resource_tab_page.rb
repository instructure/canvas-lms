# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../../helpers/color_common"

module K5ResourceTabPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------
  #

  def cancel_button_selector
    "//button[.//*[. = 'Cancel']]"
  end

  def course_list_selector
    "//*[@aria-label = 'Choose a Course']//a"
  end

  def course_selection_modal_selector
    "[aria-label='Choose a Course']"
  end

  def email_link_selector(email_address)
    "a[href = 'mailto:#{email_address}']"
  end

  def important_info_content_selector
    ".user_content"
  end

  def important_info_edit_pencil_selector
    "[data-testid='important-info-edit']"
  end

  def important_info_link_selector
    ".syllabus"
  end

  def instructor_bio_selector(inst_bio)
    "//*[@data-automation = 'instructor-bio' and text() = '#{inst_bio}']"
  end

  def instructor_role_selector(inst_role)
    "//*[@data-automation = 'instructor-role' and text() = '#{inst_role}']"
  end

  def k5_app_button_selector
    "[data-testid='k5-app-button']"
  end

  def message_button_selector
    "//button[.//*[contains(text(),'Send a message to')]]"
  end

  def message_input_selector
    "textarea[placeholder = 'Message']"
  end

  def message_modal_selector(user_name)
    "[aria-label='Message #{user_name}']"
  end

  def send_button_selector
    "//button[.//*[. = 'Send']]"
  end

  def staff_selector(staff_name)
    "h3:contains('#{staff_name}')"
  end

  def subject_input_selector
    "input[placeholder = 'No subject']"
  end

  #------------------------- Elements --------------------------

  def cancel_button
    fxpath(cancel_button_selector)
  end

  def course_list
    ffxpath(course_list_selector)
  end

  def course_selection_modal
    f(course_selection_modal_selector)
  end

  def email_link(email_address)
    f(email_link_selector(email_address))
  end

  def important_info_link
    f(important_info_link_selector)
  end

  def important_info_content
    f(important_info_content_selector)
  end

  def important_info_content_list
    ff(important_info_content_selector)
  end

  def important_info_edit_pencil
    f(important_info_edit_pencil_selector)
  end

  def instructor_bio(instructor_bio)
    fxpath(instructor_bio_selector(instructor_bio))
  end

  def instructor_role(role_type)
    fxpath(instructor_role_selector(role_type))
  end

  def k5_app_buttons
    ff(k5_app_button_selector)
  end

  def message_button
    fxpath(message_button_selector)
  end

  def message_input
    f(message_input_selector)
  end

  def message_modal(user_name)
    f(message_modal_selector(user_name))
  end

  def send_button
    fxpath(send_button_selector)
  end

  def staff_heading(staff_name)
    fj(staff_selector(staff_name))
  end

  def subject_input
    f(subject_input_selector)
  end

  #----------------------- Actions & Methods -------------------------
  #----------------------- Click Items -------------------------------

  def click_cancel_button
    cancel_button.click
  end

  def click_important_info_edit_pencil
    important_info_edit_pencil.click
  end

  def click_k5_button(button_item)
    k5_app_buttons[button_item].click
  end

  def click_message_button
    message_button.click
  end

  def click_send_button
    send_button.click
  end

  #------------------------------Retrieve Text----------------------#

  def k5_resource_button_names_list
    k5_app_buttons.map(&:text)
  end

  #----------------------------Element Management---------------------#

  def important_info_text_list
    important_info_content_list.map(&:text)
  end

  def is_cancel_available?
    element_value_for_attr(cancel_button, "cursor") == "pointer"
  end

  def is_modal_gone?(user_name)
    wait_for_no_such_element { message_modal(user_name) }
  end

  def is_send_available?
    element_value_for_attr(send_button, "cursor") == "pointer"
  end

  def message_modal_displayed?(user_name)
    element_exists?(message_modal_selector(user_name))
  end
end
