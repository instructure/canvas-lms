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

require_relative "../../common"

class MoveComponent
  include SeleniumDependencies

  def initialize(block)
    @block = block
  end

  def move_button
    f("[data-testid='move-block-button']", @block)
  end

  def move_menu_options
    {
      up: "[data-testid='move-up-menu-item']",
      down: "[data-testid='move-down-menu-item']",
      to_top: "[data-testid='move-to-top-menu-item']",
      to_bottom: "[data-testid='move-to-bottom-menu-item']"
    }
  end

  def click_move_option(option)
    selector = move_menu_options[option]
    raise ArgumentError, "Invalid move option: '#{option}'. Valid options: #{move_menu_options.keys.join(", ")}" unless selector

    f(selector).click
    wait_for_ajaximations
  end
end
