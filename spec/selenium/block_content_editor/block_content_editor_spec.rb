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
require_relative "../common"
require_relative "../helpers/wiki_and_tiny_common"
require_relative "pages/block_content_editor_page"

describe "Block Content Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockContentEditorPage
  include WikiAndTinyCommon

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_content_editor)
    @context = @course
    create_wiki_page_with_block_content_editor(@course)
  end

  context "Create a new page" do
    it "displays Block Content Editor" do
      expect(bce_container).to be_displayed
      expect(editor_area).to be_displayed
      expect(toolbar_area).to be_displayed
    end
  end

  context "Add a block" do
    it "displays the add block modal" do
      add_block_button.click
      wait_for_ajaximations

      expect(add_block_modal).to be_displayed
      expect(block_groups.size).to be > 0
      expect(block_items.size).to be > 0
    end

    it "adds a new block" do
      add_block_button.click
      wait_for_ajaximations

      expect(block_groups.size).to be > 0
      expect(selected_block_group.text).to eq("Text")

      expect(block_items.size).to be > 0
      expect(selected_block_item.text).to eq("Text column")

      add_to_page_button.click
      wait_for_ajaximations

      expect(element_exists?(add_block_modal_selector)).to be false
      expect(block_layout).to be_displayed
      expect(add_block_button).to be_displayed
    end
  end

  context "Block menu options" do
    before do
      add_a_block("Image", "Image + text")
    end

    it "duplicates a block" do
      first_block.duplicate_button.click
      wait_for_ajaximations

      expect(blocks.size).to eq(2)
    end

    it "removes a block" do
      first_block.remove_button.click
      wait_for_ajaximations

      expect(blocks.size).to eq(0)
    end

    it "opens settings tray" do
      first_block.settings_button.click
      wait_for_ajaximations

      expect(settings_tray).to be_displayed
    end
  end

  context "Move blocks" do
    before do
      add_a_block("Interactive element", "Button")
      add_a_block("Divider", "Separator line")
    end

    shared_examples "block movement" do |block_selector, move_direction, expected_order|
      it "moves a block #{move_direction}" do
        expected_labels = expected_order.map { |block_name| send(block_name).block_type_label.text }
        target_block = send(block_selector)
        target_block.move_component.move_button.click
        wait_for_ajaximations

        target_block.move_component.click_move_option(move_direction)
        wait_for_ajaximations

        actual_labels = blocks.map { |block| block.block_type_label.text }
        expect(actual_labels).to eq(expected_labels)
      end
    end

    include_examples "block movement", :last_block, :up, [:last_block, :first_block]
    include_examples "block movement", :first_block, :down, [:last_block, :first_block]
    include_examples "block movement", :last_block, :to_top, [:last_block, :first_block]
    include_examples "block movement", :first_block, :to_bottom, [:last_block, :first_block]
  end

  context "Undo/Redo" do
    it "has undo/redo buttons disabled initially" do
      expect(toolbar_component.undo_button).to be_disabled
      expect(toolbar_component.redo_button).to be_disabled
    end

    it "handles undo operation correctly" do
      add_a_block("Text", "Text column")
      expect(blocks.size).to eq(1)
      expect(toolbar_component.undo_button).to be_enabled

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(0)
      expect(toolbar_component.undo_button).to be_disabled
    end

    it "handles redo operation correctly" do
      add_a_block("Text", "Text column")
      expect(blocks.size).to eq(1)
      expect(toolbar_component.redo_button).to be_disabled

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(0)
      expect(toolbar_component.redo_button).to be_enabled

      toolbar_component.redo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(1)
      expect(toolbar_component.redo_button).to be_disabled
    end

    it "has redo button disabled after a new action" do
      add_a_block("Text", "Text column")

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(0)
      expect(toolbar_component.redo_button).to be_enabled

      add_a_block("Image", "Image + text")
      expect(toolbar_component.redo_button).to be_disabled
    end

    it "maintains a history chain" do
      add_a_block("Text", "Text column")
      add_a_block("Image", "Image + text")
      expect(blocks.size).to eq(2)
      expect(first_block.block_type_label.text).to eq("Text column")
      expect(last_block.block_type_label.text).to eq("Image + text")

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(1)
      expect(first_block.block_type_label.text).to eq("Text column")

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(0)
      expect(toolbar_component.undo_button).to be_disabled

      toolbar_component.redo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(1)
      expect(first_block.block_type_label.text).to eq("Text column")

      toolbar_component.redo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(2)
      expect(first_block.block_type_label.text).to eq("Text column")
      expect(last_block.block_type_label.text).to eq("Image + text")
      expect(toolbar_component.redo_button).to be_disabled
    end
  end

  context "Preview Mode" do
    before do
      add_a_block("Text", "Text column")
      toolbar_component.preview_button.click
      wait_for_ajaximations
    end

    it "toggles preview mode when preview button is clicked" do
      expect(element_exists?(block_selector)).to be false
      expect(preview_component.preview_selector_bar).to be_displayed
      expect(preview_component.preview_layout).to be_displayed
    end

    it "shows only preview button on toolbar in preview mode" do
      expect(toolbar_component.toolbar_buttons.size).to eq(1)
      expect(toolbar_component.preview_button).to be_displayed
      expect(element_exists?(toolbar_component.undo_button_selector)).to be false
      expect(element_exists?(toolbar_component.redo_button_selector)).to be false
      expect(element_exists?(toolbar_component.accessibility_checker_selector)).to be false
    end

    it "shows desktop view as default" do
      expect(preview_component.tabs.size).to eq(3)
      expect(preview_component.is_tab_active?(:desktop)).to be true
      expect(preview_component.is_tab_active?(:tablet)).to be false
      expect(preview_component.is_tab_active?(:mobile)).to be false
    end

    shared_examples "preview mode switching" do |target_mode, other_modes|
      it "switches to #{target_mode} mode" do
        tab_method = "#{target_mode}_tab"
        preview_component.send(tab_method).click
        wait_for_ajaximations

        expect(preview_component.is_tab_active?(target_mode)).to be true
        other_modes.each do |mode|
          expect(preview_component.is_tab_active?(mode)).to be false
        end
      end
    end

    include_examples "preview mode switching", :tablet, [:desktop, :mobile]
    include_examples "preview mode switching", :mobile, [:desktop, :tablet]
    include_examples "preview mode switching", :desktop, [:tablet, :mobile]

    it "exits preview mode when preview button is clicked" do
      expect(preview_component.preview_layout).to be_displayed

      toolbar_component.preview_button.click
      wait_for_ajaximations
      expect(element_exists?(preview_component.preview_layout_selector)).to be false
      expect(block_layout).to be_displayed
    end

    it "has different widths for each device mode" do
      desktop_mode_width = preview_component.preview_container_width

      preview_component.tablet_tab.click
      wait_for_ajaximations
      tablet_mode_width = preview_component.preview_container_width

      preview_component.mobile_tab.click
      wait_for_ajaximations
      mobile_mode_width = preview_component.preview_container_width

      expect(desktop_mode_width).to be > tablet_mode_width
      expect(tablet_mode_width).to be > mobile_mode_width
    end

    it "renders preview content without block edit controls" do
      expect(element_exists?(add_block_button_selector)).to be false
      blocks.each do |block|
        expect(element_exists?(block.block_menu_selector)).to be false
        expect(element_exists?(block.block_type_label_selector)).to be false
      end
    end
  end
end
