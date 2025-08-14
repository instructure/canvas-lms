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

module BlockContentEditorPage
  def add_block_modal_selector
    "[data-testid='add-block-modal']"
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
    f("button[data-testid='add-block-button']")
  end

  def add_block_modal
    f(add_block_modal_selector)
  end

  def block_groups
    f("[data-testid='grouped-select-groups']")
  end

  def selected_block_group
    f(".grouped-select-group.selected")
  end

  def block_items
    f("[data-testid='grouped-select-items']")
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
    f(".base-block-layout")
  end

  def create_wiki_page_with_block_content_editor(course)
    get "/courses/#{course.id}/pages"
    f("a.new_page").click
    wait_for_ajaximations
    click_option(f("[data-testid=\"choose-an-editor-dropdown\"]"), "Try the Block Content Editor")
    fj("button:contains('Continue')").click
    wait_for_ajaximations
  end
end
