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
require_relative "../components/block_component"
require_relative "../components/toolbar_component"
require_relative "../components/preview_component"
require_relative "../components/block_modes/block_component_factory"

module BlockContentEditorPage
  def add_block_modal_selector
    "[data-testid='add-block-modal']"
  end

  def block_selector
    ".base-block-layout"
  end

  def add_block_button_selector
    "button[data-testid='add-block-button']"
  end

  def bce_container
    f(".block-content-editor-container")
  end

  def editor_area
    f(".editor-area")
  end

  def toolbar_area
    f(".toolbar-area")
  end

  def add_block_button
    f(add_block_button_selector)
  end

  def add_block_modal
    f(add_block_modal_selector)
  end

  def block_groups
    ff("[data-testid='grouped-select-groups']>div")
  end

  def selected_block_group
    f(".grouped-select-group.selected")
  end

  def block_items
    ff("[data-testid='grouped-select-items']>div")
  end

  def selected_block_item
    f(".grouped-select-item.selected")
  end

  def add_block_modal_close_button
    f("[data-testid='add-modal-close-button']")
  end

  def add_block_modal_cancel_button
    f("[data-testid='add-modal-cancel-button']")
  end

  def add_to_page_button
    f("[data-testid='add-modal-add-to-page-button']")
  end

  def block_layout
    f(block_selector)
  end

  def blocks(mode: :edit)
    find_all_with_jquery(block_selector).map { |element| BlockComponentFactory.create(element, mode:) }
  end

  def edit_blocks
    blocks(mode: :edit)
  end

  def preview_blocks
    blocks(mode: :preview)
  end

  def settings_tray
    f("[data-testid='settings-tray']")
  end

  def block(index = 0, mode: :edit)
    blocks(mode:)[index]
  end

  def first_block(mode: :edit)
    blocks(mode:).first
  end

  def last_block(mode: :edit)
    blocks(mode:).last
  end

  def toolbar_component
    ToolbarComponent.new
  end

  def preview_component
    PreviewComponent.new
  end

  def create_wiki_page_with_block_content_editor(course)
    get "/courses/#{course.id}/pages"
    f("a.new_page").click
    wait_for_ajaximations
    click_option(f("[data-testid=\"choose-an-editor-dropdown\"]"), "Try the Block Content Editor")
    fj("button:contains('Continue')").click
    wait_for_ajaximations
  end

  def click_block_option(block_options, block_option_name)
    block_option = block_options.find { |group| group.text.include?(block_option_name) }
    raise ArgumentError, "Invalid block option: '#{block_option_name}'. Valid options: #{block_options.map(&:text).join(", ")}" unless block_option

    block_option.click
    wait_for_ajaximations
  end

  def add_a_block(block_group_name, block_item_name)
    add_block_button.click
    wait_for_ajaximations

    click_block_option(block_groups, block_group_name)
    click_block_option(block_items, block_item_name)

    add_to_page_button.click
    wait_for_ajaximations
  end
end
