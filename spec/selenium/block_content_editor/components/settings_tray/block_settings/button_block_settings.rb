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
require_relative "shared/block_title_toggle"
require_relative "shared/color_settings"
require_relative "individual_button_settings"

class ButtonBlockSettings
  include SeleniumDependencies

  attr_reader :block_title_toggle, :color_settings

  def initialize
    @block_title_toggle = BlockTitleToggle.new
    @color_settings = ColorSettings.new
    @general_button_settings = SettingsGroupComponent.new("General button settings")
    @individual_button_settings = SettingsGroupComponent.new("Individual button settings")
  end

  def full_width_buttons_toggle
    fj('input[type="checkbox"] + label:contains("Full width buttons")', @settings_tray)
  end

  def alignment_radio_option(alignment)
    fj("fieldset[role='radiogroup']:contains('Alignment') input[type='radio'] + label:contains('#{alignment}')", @settings_tray)
  end

  def button_layout_radio_option(layout)
    fj("fieldset[role='radiogroup']:contains('Button layout') input[type='radio'] + label:contains('#{layout}')", @settings_tray)
  end

  def new_button
    fj('button:contains("New button")', @settings_tray)
  end

  def individual_button_settings(index)
    IndividualButtonSettings.new(@individual_button_settings, index)
  end
end
