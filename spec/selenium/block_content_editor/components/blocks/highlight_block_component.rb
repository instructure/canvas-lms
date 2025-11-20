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
require_relative "../settings_tray/block_settings/highlight_block_settings"

class HighlightBlockComponent < BlockComponent
  BLOCK_TYPE = "Highlight"
  BLOCK_SELECTOR = "[data-testid='highlight-block']"

  def settings
    @settings ||= HighlightBlockSettings.new
  end

  def highlight_icon_selector
    "[data-testid='highlight-icon']"
  end

  def highlight
    f("[data-testid='highlight-block']", @block)
  end

  def highlight_icon
    f(highlight_icon_selector, highlight)
  end

  def input
    f("input", highlight)
  end
end
