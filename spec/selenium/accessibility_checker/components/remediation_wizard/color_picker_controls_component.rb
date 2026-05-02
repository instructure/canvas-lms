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

class ColorPickerControlsComponent
  include SeleniumDependencies

  def color_input
    f("[role='dialog'] [data-testid='contrast-ratio-form'] input")
  end

  def enter_color(hex_value)
    input = color_input
    input.click
    input.send_keys([:control, "a"])
    input.send_keys(hex_value.delete_prefix("#"))
    wait_for_ajaximations
  end

  def clear_color
    input = color_input
    input.click
    input.send_keys([:control, "a"], :backspace)
    input.send_keys(:tab)
    wait_for_ajaximations
  end

  def color_value
    value = color_input.attribute("value")
    value.start_with?("#") ? value : "##{value}"
  end

  def required_message_visible?
    !!fj("[role='dialog'] *:contains('You must select a color to proceed.')")&.displayed?
  rescue
    false
  end
end
