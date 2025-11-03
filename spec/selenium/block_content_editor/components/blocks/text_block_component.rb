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
require_relative "../settings_tray/block_settings/text_block_settings"

class TextBlockComponent < BlockComponent
  BLOCK_TYPE = "Text column"
  BLOCK_SELECTOR = "div p"

  attr_reader :block_title

  def initialize(block)
    super
    @block_title = BlockTitleComponent.new(@block)
  end

  def settings
    @settings ||= TextBlockSettings.new
  end

  def rce_controller_selector
    "textarea"
  end

  def text_content
    f("p", @block)
  end

  def type(text)
    type_in_tiny(rce_controller_selector, text)
  end
end
