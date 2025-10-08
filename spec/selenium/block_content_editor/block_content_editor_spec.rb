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
require_relative "components/blocks/block_title_component"
require_relative "components/settings_tray/block_settings/shared/block_title_toggle"
require_relative "components/settings_tray/block_settings/shared/color_settings"

describe "Block Content Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockContentEditorPage
  include WikiAndTinyCommon

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_content_editor)
    @course.enable_feature!(:block_content_editor_eap)
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
      blocks.first.duplicate_button.click
      wait_for_ajaximations

      expect(blocks.size).to eq(2)
    end

    it "removes a block" do
      blocks.first.remove_button.click
      wait_for_ajaximations

      expect(blocks.size).to eq(0)
    end

    it "opens settings tray" do
      blocks.first.settings_button.click
      wait_for_ajaximations

      expect(blocks.first.settings_tray).to be_displayed
    end
  end

  context "Move blocks" do
    before do
      add_a_block("Interactive element", "Button")
      add_a_block("Divider", "Separator line")
    end

    shared_examples "block movement" do |block_selector, move_direction, expected_order|
      let(:first_block) { blocks.first }
      let(:last_block) { blocks.last }

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
      expect(blocks.first.block_type_label.text).to eq("Text column")
      expect(blocks.last.block_type_label.text).to eq("Image + text")

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(1)
      expect(blocks.first.block_type_label.text).to eq("Text column")

      toolbar_component.undo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(0)
      expect(toolbar_component.undo_button).to be_disabled

      toolbar_component.redo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(1)
      expect(blocks.first.block_type_label.text).to eq("Text column")

      toolbar_component.redo_button.click
      wait_for_ajaximations
      expect(blocks.size).to eq(2)
      expect(blocks.first.block_type_label.text).to eq("Text column")
      expect(blocks.last.block_type_label.text).to eq("Image + text")
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
      expect(element_exists?(base_block_edit_layout_selector)).to be false
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

  shared_examples "editing background color" do
    it "changes background color" do
      blocks.first.settings_button.click
      wait_for_ajaximations

      color_settings = blocks.first.settings.color_settings
      color_settings.change_background_color("ff0000")
      wait_for_ajaximations
      expect(blocks.first.block.css_value("background-color")).to eq("rgba(255, 0, 0, 1)")
    end

    it "preserves background color after closing settings tray" do
      blocks.first.settings_button.click
      wait_for_ajaximations

      color_settings = blocks.first.settings.color_settings
      color_settings.change_background_color("ff0000")
      wait_for_ajaximations
      expect(blocks.first.block.css_value("background-color")).to eq("rgba(255, 0, 0, 1)")

      blocks.first.settings_tray_component.close_button.click
      wait_for_ajaximations
      expect(blocks.first.block.css_value("background-color")).to eq("rgba(255, 0, 0, 1)")
    end
  end

  shared_examples "editing block title" do
    it "edits block title" do
      block_title = blocks_with_title.first.block_title.title
      expect(block_title).to be_displayed
      expect(block_title.text).to eq("Click to edit")

      block_title.click
      wait_for_ajaximations

      block_title_input = blocks_with_title.first.block_title.title_input
      expect(block_title_input).to be_displayed

      block_title_input.send_keys("Block Title")
      click_outside_block

      block_title = blocks_with_title.first.block_title.title
      expect(block_title.text).to eq("Block Title")
    end

    it "toggles block title" do
      block_title = blocks.first.block_title.title
      expect(block_title).to be_displayed

      blocks_with_title.first.settings_button.click
      wait_for_ajaximations

      block_title_toggle = blocks_with_title.first.settings.block_title_toggle.toggle
      block_title_toggle.click
      wait_for_ajaximations
      expect(blocks_with_title.first.block_title.is_title_present?).to be false

      settings_tray_close_button = blocks_with_title.first.settings_tray_component.close_button
      settings_tray_close_button.click
      wait_for_ajaximations
      expect(blocks_with_title.first.block_title.is_title_present?).to be false

      blocks_with_title.first.settings_button.click
      wait_for_ajaximations

      block_title_toggle = blocks_with_title.first.settings.block_title_toggle.toggle
      block_title_toggle.click
      wait_for_ajaximations
      block_title = blocks_with_title.first.block_title.title
      expect(block_title).to be_displayed

      settings_tray_close_button = blocks_with_title.first.settings_tray_component.close_button
      settings_tray_close_button.click
      wait_for_ajaximations
      expect(block_title).to be_displayed
    end

    it "changes title color" do
      blocks_with_title.first.settings_button.click
      wait_for_ajaximations

      color_settings = blocks_with_title.first.settings.color_settings
      color_settings.change_title_color("ff0000")
      block_title_color = blocks_with_title.first.block_title.title.css_value("color")
      expect(block_title_color).to eq("rgba(255, 0, 0, 1)")
    end

    it "preserves title color after closing settings tray" do
      blocks_with_title.first.settings_button.click
      wait_for_ajaximations

      color_settings = blocks_with_title.first.settings.color_settings
      color_settings.change_title_color("ff0000")
      block_title_color = blocks_with_title.first.block_title.title.css_value("color")
      expect(block_title_color).to eq("rgba(255, 0, 0, 1)")

      blocks_with_title.first.settings_tray_component.close_button.click
      wait_for_ajaximations
      block_title_color = blocks_with_title.first.block_title.title.css_value("color")
      expect(block_title_color).to eq("rgba(255, 0, 0, 1)")
    end
  end

  shared_examples "no block title" do
    it "does not display block title" do
      block_title_component = BlockTitleComponent.new(blocks.first.block)
      expect(block_title_component.is_title_present?).to be false
    end

    it "does not have block title toggle in settings tray" do
      blocks.first.settings_button.click
      wait_for_ajaximations

      block_title_toggle = BlockTitleToggle.new
      expect(element_exists?(block_title_toggle.toggle_selector, true)).to be false
    end

    it "does not have title color settings in settings tray" do
      blocks.first.settings_button.click
      wait_for_ajaximations

      color_settings = ColorSettings.new
      expect(element_exists?(color_settings.title_color_setting_selector, true)).to be false
    end
  end

  context "Editing blocks" do
    context "Separator block" do
      before do
        add_a_block("Divider", "Separator line")
      end

      include_examples "editing background color"
      include_examples "no block title"

      it "changes separator color" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        blocks.first.settings.change_separator_color("00ff00")
        wait_for_ajaximations
        expect(blocks.first.separator_line.css_value("border-color")).to eq("rgb(0, 255, 0)")
      end

      it "preserves separator color after closing settings tray" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        blocks.first.settings.change_separator_color("00ff00")
        wait_for_ajaximations
        expect(blocks.first.separator_line.css_value("border-color")).to eq("rgb(0, 255, 0)")

        blocks.first.settings_tray_component.close_button.click
        wait_for_ajaximations
        expect(blocks.first.separator_line.css_value("border-color")).to eq("rgb(0, 255, 0)")
      end

      it "changes separator thickness" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        settings = blocks.first.settings
        separator_line = blocks.first.separator_line
        thicknesses = {}

        %w[Small Medium Large].each do |size|
          settings.separator_size_radio_option(size).click
          wait_for_ajaximations
          thicknesses[size] = separator_line.css_value("border-bottom-width").to_f
        end

        aggregate_failures "separator thickness relationships" do
          thicknesses.each_value do |thickness|
            expect(thickness).to be > 0
          end

          expect(thicknesses["Small"]).to be < thicknesses["Medium"]
          expect(thicknesses["Medium"]).to be < thicknesses["Large"]
          expect(thicknesses["Small"]).to be < thicknesses["Large"]
        end

        blocks.first.settings_tray_component.close_button.click
        wait_for_ajaximations

        aggregate_failures "separator thickness relationships" do
          thicknesses.each_value do |thickness|
            expect(thickness).to be > 0
          end

          expect(thicknesses["Small"]).to be < thicknesses["Medium"]
          expect(thicknesses["Medium"]).to be < thicknesses["Large"]
          expect(thicknesses["Small"]).to be < thicknesses["Large"]
        end
      end
    end

    context "Highlight block" do
      before do
        add_a_block("Text", "Highlight")
      end

      include_examples "editing background color"
      include_examples "no block title"

      it "toggles highlight icon display" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        toggle = blocks.first.settings.display_icon_toggle
        expect(blocks.first.highlight_icon).to be_displayed

        toggle.click
        wait_for_ajaximations
        expect(element_exists?(blocks.first.highlight_icon_selector)).to be false

        blocks.first.settings_tray_component.close_button.click
        wait_for_ajaximations
        expect(element_exists?(blocks.first.highlight_icon_selector)).to be false

        blocks.first.settings_button.click
        wait_for_ajaximations

        toggle = blocks.first.settings.display_icon_toggle
        toggle.click
        wait_for_ajaximations
        expect(blocks.first.highlight_icon).to be_displayed

        blocks.first.settings_tray_component.close_button.click
        wait_for_ajaximations
        expect(blocks.first.highlight_icon).to be_displayed
      end

      it "changes highlight color" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        blocks.first.settings.change_highlight_color("00ff00")
        wait_for_ajaximations
        expect(blocks.first.highlight.css_value("background-color")).to eq("rgba(0, 255, 0, 1)")
      end

      it "preserves highlight color after closing settings tray" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        blocks.first.settings.change_highlight_color("00ff00")
        wait_for_ajaximations
        expect(blocks.first.highlight.css_value("background-color")).to eq("rgba(0, 255, 0, 1)")

        blocks.first.settings_tray_component.close_button.click
        wait_for_ajaximations
        expect(blocks.first.highlight.css_value("background-color")).to eq("rgba(0, 255, 0, 1)")
      end
    end

    context "Media block" do
      before do
        add_a_block("Multimedia", "Media")
      end

      include_examples "editing block title"
      include_examples "editing background color"

      it "displays placeholder in edit preview mode when no media is added" do
        expect(blocks.first.media_placeholder).to be_displayed
        expect(element_exists?(blocks.first.add_media_button_selector)).to be false
        expect(element_exists?(blocks.first.media_content_selector)).to be false
      end

      it "displays add media button in edit mode when no media is added" do
        blocks.first.media_placeholder.click
        wait_for_ajaximations

        expect(blocks.first.add_media_button).to be_displayed
        expect(element_exists?(blocks.first.media_placeholder_selector)).to be false
        expect(element_exists?(blocks.first.media_content_selector)).to be false
      end

      it "displays add media button in settings tray when no media is added" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        settings = blocks.first.settings

        expect(settings.choose_media_button).to be_displayed
        expect(settings.choose_media_button.text).to eq("Add media")
        expect(element_exists?(settings.replace_media_button_selector, true)).to be false
      end

      it "adds media" do
        blocks.first.media_placeholder.click
        wait_for_ajaximations

        video_url = "https://www.youtube.com/watch?v=dwXwah-feFk"
        embed_url = "https://www.youtube.com/embed/dwXwah-feFk"
        blocks.first.add_external_media(video_url)

        expect(blocks.first.media_content).to be_displayed
        expect(blocks.first.media_content.attribute("src")).to eq(embed_url)
      end

      it("adds media from settings tray") do
        blocks.first.settings_button.click
        wait_for_ajaximations

        settings = blocks.first.settings

        video_url = "https://www.youtube.com/watch?v=dwXwah-feFk"
        embed_url = "https://www.youtube.com/embed/dwXwah-feFk"
        settings.add_external_media_from_settings_tray(video_url)

        expect(blocks.first.media_content).to be_displayed
        expect(blocks.first.media_content.attribute("src")).to eq(embed_url)
      end

      it "does not display placeholder after media has been added" do
        blocks.first.media_placeholder.click
        wait_for_ajaximations

        video_url = "https://www.youtube.com/watch?v=dwXwah-feFk"
        blocks.first.add_external_media(video_url)

        expect(element_exists?(blocks.first.media_placeholder_selector)).to be false
        expect(element_exists?(blocks.first.add_media_button_selector)).to be false
      end

      it "displays replace media button in settings tray after media has been added" do
        blocks.first.media_placeholder.click
        wait_for_ajaximations

        video_url = "https://www.youtube.com/watch?v=dwXwah-feFk"
        blocks.first.add_external_media(video_url)

        blocks.first.settings_button.click
        wait_for_ajaximations

        settings = blocks.first.settings
        expect(settings.replace_media_button).to be_displayed
        expect(settings.replace_media_button.text).to eq("Replace media")
        expect(element_exists?(settings.choose_media_button_selector, true)).to be false
      end

      it "preserves media after closing settings tray" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        settings = blocks.first.settings

        video_url = "https://www.youtube.com/watch?v=dwXwah-feFk"
        embed_url = "https://www.youtube.com/embed/dwXwah-feFk"
        settings.add_external_media_from_settings_tray(video_url)
        expect(blocks.first.media_content).to be_displayed
        expect(blocks.first.media_content.attribute("src")).to eq(embed_url)

        blocks.first.settings_tray_component.close_button.click
        wait_for_ajaximations

        expect(blocks.first.media_content).to be_displayed
        expect(blocks.first.media_content.attribute("src")).to eq(embed_url)
      end

      it "replaces media from settings tray" do
        blocks.first.settings_button.click
        wait_for_ajaximations

        settings = blocks.first.settings

        video_url = "https://www.youtube.com/watch?v=dwXwah-feFk"
        embed_url = "https://www.youtube.com/embed/dwXwah-feFk"
        settings.add_external_media_from_settings_tray(video_url)

        expect(blocks.first.media_content).to be_displayed
        expect(blocks.first.media_content.attribute("src")).to eq(embed_url)

        new_video_url = "https://www.youtube.com/watch?v=5MgBikgcWnY"
        new_embed_url = "https://www.youtube.com/embed/5MgBikgcWnY"
        settings.replace_with_external_media(new_video_url)
        wait_for_ajaximations

        expect(blocks.first.media_content).to be_displayed
        expect(blocks.first.media_content.attribute("src")).to eq(new_embed_url)
      end
    end
  end
end
