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
require_relative "block_modes/block_component_factory"

class PreviewComponent
  include SeleniumDependencies

  def preview_layout_selector
    "[data-testid='block-content-preview-layout']"
  end

  def preview_layout
    f(preview_layout_selector)
  end

  def preview_selector_bar
    f(".preview-selector-bar-container")
  end

  def tabs
    ff("[role='tablist'] > *", preview_layout)
  end

  def desktop_tab
    f("#tab-desktop")
  end

  def tablet_tab
    f("#tab-tablet")
  end

  def mobile_tab
    f("#tab-mobile")
  end

  def preview_frame
    f("[data-testid='scale-view']")
  end

  def preview_container_width
    preview_frame.size.width
  end

  def preview_blocks
    ff(".content-wrapper>div", preview_layout).map do |element|
      BlockComponentFactory.create(element, mode: :preview)
    end
  end

  def first_preview_block
    preview_blocks.first
  end

  def preview_options
    {
      desktop: desktop_tab,
      tablet: tablet_tab,
      mobile: mobile_tab
    }
  end

  def is_tab_active?(tab_option)
    tab = preview_options[tab_option]
    raise ArgumentError, "Invalid tab option: #{tab_option}. Valid options: #{preview_options.keys.join(", ")}" unless tab

    tab["aria-selected"] == "true"
  end
end
