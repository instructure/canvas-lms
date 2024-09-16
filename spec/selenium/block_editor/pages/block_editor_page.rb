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

module BlockEditorPage
  def create_wiki_page(course)
    get "/courses/#{course.id}/pages"
    f("a.new_page").click
    wait_for_block_editor
  end

  def build_wiki_page(page)
    file = File.open(File.expand_path(File.dirname(__FILE__) + "../../../../fixtures/block-editor/#{page}"))
    block_page_content = file.read
    block_page = @course.wiki_pages.create!(title: "Block Page")

    block_page.update!(
      block_editor_attributes: {
        time: Time.now.to_i,
        version: "1",
        blocks: block_page_content
      }
    )
    block_page
  end

  def active_element
    driver.execute_script("return document.activeElement") # rubocop:disable Specs/NoExecuteScript
  end

  def block_editor
    f(".block-editor")
  end

  def block_editor_editor
    f(".block-editor-editor")
  end

  def topbar
    f(".topbar")
  end

  # Stepper
  def stepper_modal_selector
    '[role="dialog"][aria-label="Create a new page"]'
  end

  def stepper_modal
    f(stepper_modal_selector)
  end

  def stepper_start_from_scratch
    fxpath('//button[.//*[@aria-labelledby="start-from-scratch-desc"]]')
  end

  def stepper_start_from_template
    fxpath('//button[.//*[@aria-labelledby="select-a-template-desc"]]')
  end

  def stepper_next_button
    fj('button:contains("Next")')
  end

  def stepper_start_creating_button
    fj('button:contains("Start Creating")')
  end

  def stepper_start_editing_button
    fj('button:contains("Start Editing")')
  end

  def stepper_select_page_sections
    f('[data-testid="stepper-page-sections"]')
  end

  def stepper_hero_section_checkbox
    fxpath('//*[@id="heroWithText"]/..')
  end

  def stepper_select_color_palette
    f('[data-testid="stepper-color-palette"]')
  end

  def stepper_select_font_pirings
    f('[data-testid="stepper-font-pairings"]')
  end

  # Block Toolbox
  def block_toolbox_toggle
    f("#toolbox-toggle+label")
  end

  def block_toolbox
    f('[role="dialog"][aria-label="Toolbox"]')
  end

  def block_toolbox_box_by_block_name(block_name)
    f(".toolbox-item.item-#{block_name}-block")
  end

  def block_toolbox_image
    f(".toolbox-item.item-image-block")
  end

  def block_toolbox_button
    f(".toolbox-item.item-button-block")
  end

  def block_toolbox_text
    f(".toolbox-item.item-text-block")
  end

  def block_toolbox_group
    f(".toolbox-item.item-group-block")
  end

  # Blocks
  def block_resize_handle_selector(direction)
    ".block-resizer .moveable-#{direction}"
  end

  def block_resize_handle(direction = se)
    f(block_resize_handle_selector(direction))
  end

  def block_toolbar
    f(".block-toolbar")
  end

  def block_toolbar_up_button
    driver.execute_script("return document.querySelector('svg[name=\"IconArrowUp\"]').closest('button')") # rubocop:disable Specs/NoExecuteScript
  end

  def block_toolbar_delete_button_selector
    ".block-toolbar button:contains('Delete')"
  end

  def block_toolbar_delete_button
    fj(block_toolbar_delete_button_selector)
  end

  def click_block_toolbar_menu_item(menu_button_name, menu_item_name)
    fj("button:contains('#{menu_button_name}')").click
    fj("[role=\"menuitemcheckbox\"]:contains('#{menu_item_name}')").click
  end

  def image_block_image
    f(".block.image-block img")
  end

  def image_block_upload_button
    f('[data-testid="upload-image-button"]')
  end

  def image_block_alt_text_button
    f('[data-testid="alt-text-button"]')
  end

  def image_block_alt_text_input
    f("textarea[placeholder='Image Description']")
  end

  def group_block_inner_selector
    ".group-block__inner"
  end

  def group_block_dropzone
    f(group_block_inner_selector)
  end

  def text_block
    f(".text-block")
  end

  # Sections
  def blank_section
    f(".blank-section__inner")
  end

  def hero_section
    f(".hero-section")
  end

  # Add Image Modal
  def image_modal_tabs
    ff('[role="tab"]')
  end

  def course_images_tab
    image_modal_tabs[2]
  end

  def user_images_tab
    image_modal_tabs[3]
  end

  def image_thumbnails
    ff('[class*="view--block-img"]')
  end

  def submit_button
    f('button[type="submit"]')
  end

  # columns section
  def columns_section
    f(".columns-section")
  end

  def columns_input
    f('[data-testid="columns-input"]')
  end

  def columns_input_increment
    fxpath("//*[@data-testid='columns-input']/following-sibling::*//button[1]")
  end

  def columns_input_decrement
    fxpath("//*[@data-testid='columns-input']/following-sibling::*//button[2]")
  end

  # blocks
  def page_block
    f(".page-block")
  end

  def group_block
    f(".group-block")
  end

  def group_blocks
    ff(".group-block")
  end

  def icon_block
    f(".icon-block")
  end

  def icon_blocks
    ff(".icon-block")
  end

  def icon_block_title
    f(".icon-block > svg > title")
  end

  def icon_block_titles
    ff(".icon-block > svg > title")
  end

  def select_an_icon_popup
    f("[role='dialog'][aria-label='Select an icon']")
  end

  def select_an_icon_popup_icon(name)
    fxpath("//*[local-name()='svg']/*[local-name()='#{name}']", select_an_icon_popup)
  end

  def image_block
    f(".image-block")
  end

  def section_menu
    f(".section-menu")
  end

  def section_menu_menu
    f(".section-menu ul[role='menu']")
  end

  def kb_focus_block_toolbar
    driver.action.key_down(:control).send_keys(:f9).key_up(:control).perform
  end
end
