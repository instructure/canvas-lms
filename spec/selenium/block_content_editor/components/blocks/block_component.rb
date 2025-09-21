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

require_relative "../../../common"
require_relative "../move_component"
require_relative "../settings_tray/settings_tray_component"

class BlockComponent
  include SeleniumDependencies

  attr_reader :block

  def initialize(block)
    @block = block
  end

  def block_menu_selector
    "[data-testid='block-menu']"
  end

  def block_type_label_selector
    "[data-testid='block-type-label']"
  end

  def block_menu
    f(block_menu_selector, @block)
  end

  def duplicate_button
    f("[data-testid='copy-block-button']", @block)
  end

  def settings_button
    f("[data-testid='block-settings-button']", @block)
  end

  def remove_button
    f("[data-testid='remove-block-button']", @block)
  end

  def block_type_label
    f(block_type_label_selector, @block)
  end

  def move_component
    MoveComponent.new(@block)
  end

  def settings_tray_component
    SettingsTrayComponent.new
  end

  def settings_tray
    @settings_tray ||= settings_tray_component.settings_tray
  end
end
