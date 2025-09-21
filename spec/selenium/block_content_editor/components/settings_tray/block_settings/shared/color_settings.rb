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

require_relative "../../../../../common"
require_relative "../../settings_group_component"

class ColorSettings
  include SeleniumDependencies

  def initialize(has_block_title: true)
    @background_color_label = "Background color"
    @title_color_label = has_block_title ? "Title color" : nil
    @color_settings = SettingsGroupComponent.new("Color settings")
    @background_color_setting = find_background_color_setting
    @title_color_setting = find_title_color_setting
  end

  def find_background_color_setting
    fj("[class$='colorPicker']:contains('#{@background_color_label}')", @color_settings.settings_group)
  end

  def background_color_hex_input
    f("input", @background_color_setting)
  end

  def background_color_popover_button
    f("button", @background_color_setting)
  end

  def background_color_mixer
    f('[data-testid="color-mixer"]')
  end

  def find_title_color_setting
    return nil unless @title_color_label

    fj("[class$='colorPicker']:contains('#{@title_color_label}')", @color_settings.settings_group)
  end

  def title_color_hex_input
    return nil unless @title_color_setting

    f("input", @title_color_setting)
  end

  def title_color_popover_button
    return nil unless @title_color_setting

    f("button", @title_color_setting)
  end

  def title_color_mixer
    return nil unless @title_color_setting

    f('[data-testid="color-mixer"]')
  end

  def change_background_color(hex_color)
    background_color_hex_input.click
    background_color_hex_input.send_keys([:control, "a"])
    background_color_hex_input.send_keys(hex_color)
    background_color_hex_input.send_keys(:enter)
  end

  def change_title_color(hex_color)
    return nil unless @title_color_setting

    title_color_hex_input.click
    title_color_hex_input.send_keys([:control, "a"])
    title_color_hex_input.send_keys(hex_color)
    title_color_hex_input.send_keys(:enter)
  end
end
