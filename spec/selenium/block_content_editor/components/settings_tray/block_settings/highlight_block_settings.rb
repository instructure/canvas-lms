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

require_relative "../../../../common"
require_relative "../settings_group_component"
require_relative "shared/color_settings"

class HighlightBlockSettings
  include SeleniumDependencies

  attr_reader :color_settings

  def initialize
    @color_settings = ColorSettings.new(has_block_title: false)
    @highlight_settings = SettingsGroupComponent.new("Highlight settings")
    @highlight_color_picker = find_highlight_color_picker
    @text_color_picker = find_text_color_picker
  end

  def find_highlight_color_picker
    fj('[class$="colorPicker"]:contains("Highlight")', @highlight_settings.settings_group)
  end

  def find_text_color_picker
    fj('[class$="colorPicker"]:contains("Text")', @highlight_settings.settings_group)
  end

  def display_icon_toggle
    fj('input[type="checkbox"] + label:contains("Display icon")', @highlight_settings.settings_group)
  end

  def highlight_color_hex_input
    f("input", @highlight_color_picker)
  end

  def highlight_color_popover_button
    f("button", @highlight_color_picker)
  end

  def highlight_color_mixer
    f('[class$="colorMixer"]')
  end

  def text_color_hex_input
    f("input", @text_color_picker)
  end

  def text_color_popover_button
    f("button", @text_color_picker)
  end

  def text_color_mixer
    f('[class$="colorMixer"]')
  end

  def change_highlight_color(hex_color)
    highlight_color_hex_input.click
    highlight_color_hex_input.send_keys([:control, "a"])
    highlight_color_hex_input.send_keys(hex_color)
    highlight_color_hex_input.send_keys(:enter)
  end
end
