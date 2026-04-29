# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../../common"

class AltTextControlsComponent
  include SeleniumDependencies

  def alt_text_input_selector
    "[role='dialog'] [data-testid='checkbox-text-input-form']"
  end

  def decorative_checkbox_selector
    "[role='dialog'] input[type='checkbox']"
  end

  def alt_text_input
    f(alt_text_input_selector)
  end

  def decorative_checkbox
    f(decorative_checkbox_selector)
  end

  def enter_alt_text(text)
    alt_text_input.clear
    alt_text_input.send_keys(text)
    wait_for_ajaximations
  end

  def clear_alt_text
    alt_text_input.send_keys([:control, "a"], :backspace)
    wait_for_ajaximations
  end

  def mark_as_decorative
    decorative_checkbox_label.click unless decorative_checked?
    wait_for_ajaximations
  end

  def unmark_as_decorative
    decorative_checkbox_label.click if decorative_checked?
    wait_for_ajaximations
  end

  def alt_text_input_value
    alt_text_input.attribute("value")
  end

  def alt_text_input_disabled?
    alt_text_input.attribute("disabled") == "true"
  end

  def alt_text_required_message_visible?
    !!fj("[role='dialog'] span:contains('Alt text is required.')")&.displayed?
  end

  def alt_text_too_long_message_visible?
    !!fj("[role='dialog'] span:contains('Keep alt text under 200 characters.')")&.displayed?
  end

  def alt_text_filename_message_visible?
    !!fj("[role='dialog'] span:contains('Alt text can not be a filename.')")&.displayed?
  end

  def decorative_checkbox_label
    decorative_checkbox.find_element(:xpath, "..")
  end

  def decorative_checked?
    decorative_checkbox.attribute("checked") == "true"
  end
end
