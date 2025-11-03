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

require_relative "block_component"
require_relative "../settings_tray/block_settings/button_block_settings"

class ButtonBlockComponent < BlockComponent
  BLOCK_TYPE = "Button"
  BLOCK_SELECTOR = "[data-testid='button-block-view']"

  attr_reader :block_title

  def initialize(block)
    super
    @block_title = BlockTitleComponent.new(@block)
  end

  def settings
    @settings ||= ButtonBlockSettings.new
  end

  def buttons
    ff("[data-button]", @block)
  end

  def button_background_color(button)
    button.find_element(:css, "span").css_value("background-color")
  end

  def button_text_color(button)
    button.find_element(:css, "span").css_value("color")
  end
end
