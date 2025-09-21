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
require_relative "block_component"
require_relative "separator_block_component"
require_relative "text_block_component"
require_relative "image_block_component"
require_relative "text_image_block_component"
require_relative "media_block_component"
require_relative "highlight_block_component"

class BlockComponentFactory
  extend SeleniumDependencies

  def self.create(element)
    block_type = determine_block_type(element)
    create_by_type(element, block_type)
  end

  def self.create_by_type(element, block_type)
    case block_type
    when "Separator line" then SeparatorBlockComponent.new(element)
    when "Text column" then TextBlockComponent.new(element)
    when "Full width image" then ImageBlockComponent.new(element)
    when "Image + text" then TextImageBlockComponent.new(element)
    when "Media" then MediaBlockComponent.new(element)
    when "Highlight" then HighlightBlockComponent.new(element)
    else BlockComponent.new(element)
    end
  end

  def self.determine_block_type(element)
    block_type_label_selector = "[data-testid='block-type-label']"
    if element_exists?(block_type_label_selector)
      type_label = f(block_type_label_selector, element)
      type_label.text
    else
      nil
    end
  end
end
