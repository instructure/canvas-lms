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
require_relative "button_block_component"
require_relative "image_block_component"
require_relative "text_image_block_component"
require_relative "media_block_component"
require_relative "highlight_block_component"

class BlockComponentFactory
  extend SeleniumDependencies

  BLOCK_TYPE_TO_COMPONENT = {
    SeparatorBlockComponent::BLOCK_TYPE => SeparatorBlockComponent,
    TextBlockComponent::BLOCK_TYPE => TextBlockComponent,
    ImageBlockComponent::BLOCK_TYPE => ImageBlockComponent,
    TextImageBlockComponent::BLOCK_TYPE => TextImageBlockComponent,
    MediaBlockComponent::BLOCK_TYPE => MediaBlockComponent,
    HighlightBlockComponent::BLOCK_TYPE => HighlightBlockComponent,
    ButtonBlockComponent::BLOCK_TYPE => ButtonBlockComponent
  }.freeze

  BLOCKS_WITH_UNIQUE_SELECTORS = [
    ButtonBlockComponent,
    SeparatorBlockComponent,
    HighlightBlockComponent,
    MediaBlockComponent
  ].freeze

  def self.create(element)
    block_type = determine_block_type(element)
    create_by_type(element, block_type)
  end

  def self.create_by_type(element, block_type)
    component_class = BLOCK_TYPE_TO_COMPONENT[block_type] || BlockComponent
    component_class.new(element)
  end

  def self.determine_block_type(element)
    block_type_label_selector = "[data-testid='block-type-label']"
    if element_exists?(block_type_label_selector)
      type_label = f(block_type_label_selector, element)
      type_label.text
    else
      determine_block_type_by_unique_element(element)
    end
  end

  def self.determine_block_type_by_unique_element(element)
    BLOCKS_WITH_UNIQUE_SELECTORS.each do |component|
      return component::BLOCK_TYPE if element_contains?(component::BLOCK_SELECTOR, element)
    end

    nil
  end

  def self.element_contains?(selector, element)
    find_all_with_jquery(selector, element).any?
  end
end
