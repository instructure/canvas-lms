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

class SeparatorBlockSettings
  include SeleniumDependencies

  attr_reader :color_settings

  def initialize
    @color_settings = ColorSettings.new(has_block_title: false)
    @separator_settings = SettingsGroupComponent.new("Separator settings")
    @separator_color_picker = find_separator_color_picker
  end

  def find_separator_color_picker
    fj('[class$="colorPicker"]:contains("Separator")', @separator_settings.settings_group)
  end

  def separator_color_hex_input
    f("input", @separator_color_picker)
  end

  def separator_color_popover_button
    f("button", @separator_color_picker)
  end

  def separator_color_mixer
    f('[class$="colorMixer"]')
  end

  def separator_size_radio_option(size)
    fj("input[name='separator-line-block-settings-thickness'] + label:contains('#{size}')", @separator_settings.settings_group)
  end

  def change_separator_color(hex_color)
    hex_input = separator_color_hex_input
    hex_input.click
    hex_input.send_keys([:control, "a"])
    hex_input.send_keys(hex_color)
    hex_input.send_keys(:enter)
  end
end
