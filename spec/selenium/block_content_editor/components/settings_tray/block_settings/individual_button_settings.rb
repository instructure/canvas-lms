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

class IndividualButtonSettings
  include SeleniumDependencies

  def initialize(parent_group, index)
    @parent_group = parent_group
    @index = index
    @button_settings_group = button_settings_group
  end

  def button_settings_group
    f("[data-testid='button-settings-toggle-#{@index}']", @parent_group.settings_group)
  end

  def delete_button
    f("[data-testid='button-settings-delete-#{@index}']", @button_settings_group)
  end

  def expand_button
    f("button[aria-expanded]", @button_settings_group)
  end

  def button_text_input
    fj("label:contains('Button text') input[type='text']", @button_settings_group)
  end

  def button_style_dropdown
    f("[data-testid='select-button-style-dropdown']", @button_settings_group)
  end

  def select_button_style(style)
    fj("ul[role='listbox'] li:contains('#{style}')")
  end

  def button_color_hex_input
    fj('[class$="colorPicker"]:contains("Button color") input', @button_settings_group)
  end

  def button_color_popover_button
    fj('[class$="colorPicker"]:contains("Button color") button', @button_settings_group)
  end

  def text_color_hex_input
    fj('[class$="colorPicker"]:contains("Text color") input', @button_settings_group)
  end

  def text_color_setting_present?
    find_all_with_jquery('[class$="colorPicker"]:contains("Text color")', @button_settings_group).any?
  end

  def text_color_popover_button
    fj('[class$="colorPicker"]:contains("Text color") button', @button_settings_group)
  end

  def color_mixer
    f('[class$="colorMixer"]', @button_settings_group)
  end

  def url_input
    fj("label:contains('URL') input", @button_settings_group)
  end

  def how_to_open_link_dropdown
    f("[data-testid='select-content-type-dropdown']", @button_settings_group)
  end

  def select_how_to_open_link(option)
    fj("ul[role='listbox'] li:contains('#{option}')")
  end

  def change_button_color(hex_color)
    button_color_hex_input.click
    button_color_hex_input.send_keys([:control, "a"])
    button_color_hex_input.send_keys(hex_color)
    button_color_hex_input.send_keys(:enter)
  end

  def change_text_color(hex_color)
    text_color_hex_input.click
    text_color_hex_input.send_keys([:control, "a"])
    text_color_hex_input.send_keys(hex_color)
    text_color_hex_input.send_keys(:enter)
  end
end
