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

  def mark_as_decorative
    unless decorative_checked?
      label = decorative_checkbox.find_element(:xpath, "..")
      label.click
    end
    wait_for_ajaximations
  end

  def alt_text_input_disabled?
    alt_text_input.attribute("disabled") == "true"
  end

  private

  def decorative_checked?
    decorative_checkbox.attribute("checked") == "true"
  end
end
