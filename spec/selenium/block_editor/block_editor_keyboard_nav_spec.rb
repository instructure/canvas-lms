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
#

require_relative "../common"
require_relative "pages/block_editor_page"

describe "Block Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage

  def focus_page_block
    f("#wikipage-title-input").click
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:tab).perform
    driver.action.send_keys(:tab).perform
  end

  def selected_block_count
    ff('[aria-selected="true"]').size
  end

  def element
    {
      great_grandparent: page_block,
      grandparent: container_block[0],
      parent_four_apples: container_block[1],
      child_icon_block: icon_block,
      child_two_apples: container_block[2],
      parent_idea_with_alarm_icons: container_block[3],
    }
  end

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @context = @course
    @block_page = build_wiki_page("kb-nav-test-page.json")
  end

  context "keyboard navigation" do
    before do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      focus_page_block
    end

    it "should navigate like a tree" do
      # see https://www.w3.org/WAI/ARIA/apg/patterns/treeview/
      # This is going to be one very long test because there's can
      # be so much setup to demonstrate the behavior of the treeview

      # Right arrow walks the tree, opening groups, and stopping at the first leaf node
      expect(page_block.attribute("aria-selected")).to eq("true")
      expect(page_block.attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_right).perform
      # the page's first child is the columns section
      expect(columns_section.attribute("aria-selected")).to eq("true")
      expect(columns_section.attribute("aria-expanded")).to eq("false")

      driver.action.send_keys(:arrow_right).perform
      # open the columns section
      expect(columns_section.attribute("aria-selected")).to eq("true")
      expect(columns_section.attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_right).perform
      # the first column
      expect(group_blocks[0].attribute("aria-selected")).to eq("true")
      expect(group_blocks[0].attribute("aria-expanded")).to eq("false")

      driver.action.send_keys(:arrow_right).perform
      # open the first column
      expect(group_blocks[0].attribute("aria-selected")).to eq("true")
      expect(group_blocks[0].attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_right).perform
      # the first icon in the first column
      icon_blocks.each_with_index do |icon_block, index|
        expect(icon_block.attribute("aria-selected")).to eq(index.zero? ? "true" : "false")
      end

      # next right arrow does nothing
      driver.action.send_keys(:arrow_right).perform
      icon_blocks.each_with_index do |icon_block, index|
        expect(icon_block.attribute("aria-selected")).to eq(index.zero? ? "true" : "false")
      end

      ###################################################################
      # up arrow walks up the tree withoug closing groups
      driver.action.send_keys(:arrow_up).perform
      # the icon's parent is the first group
      expect(group_blocks[0].attribute("aria-selected")).to eq("true")
      expect(group_blocks[0].attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_up).perform
      # the group's parent is the columns section
      expect(group_blocks[0].attribute("aria-selected")).to eq("false")
      expect(group_blocks[0].attribute("aria-expanded")).to eq("true")
      expect(columns_section.attribute("aria-selected")).to eq("true")
      expect(columns_section.attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_up).perform
      # the columns section's parent is the page block
      expect(page_block.attribute("aria-selected")).to eq("true")
      expect(page_block.attribute("aria-expanded")).to eq("true")
      expect(columns_section.attribute("aria-selected")).to eq("false")
      expect(columns_section.attribute("aria-expanded")).to eq("true")

      ###################################################################
      # down arrow walks down the tree without opening or closing groups
      driver.action.send_keys(:arrow_down).perform
      # the columns section
      expect(page_block.attribute("aria-selected")).to eq("false")
      expect(columns_section.attribute("aria-selected")).to eq("true")
      expect(columns_section.attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_down).perform
      # the group that is the first column
      expect(columns_section.attribute("aria-selected")).to eq("false")
      expect(group_blocks[0].attribute("aria-selected")).to eq("true")
      expect(group_blocks[0].attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_down).perform
      # the first icon in the column
      expect(icon_blocks[0].attribute("aria-selected")).to eq("true")

      driver.action.send_keys(:arrow_down).perform
      # the group that's in the first column
      expect(group_blocks[1].attribute("aria-selected")).to eq("true")
      expect(group_blocks[1].attribute("aria-expanded")).to eq("false")

      driver.action.send_keys(:arrow_down).perform
      # the icon after the group
      expect(icon_blocks[3].attribute("aria-selected")).to eq("true")

      driver.action.send_keys(:arrow_down).perform
      # the group that's in the second column
      expect(group_blocks[2].attribute("aria-selected")).to eq("true")
      expect(group_blocks[2].attribute("aria-expanded")).to eq("false")

      # it stops here
      driver.action.send_keys(:arrow_down).perform
      expect(group_blocks[2].attribute("aria-selected")).to eq("true")
      expect(group_blocks[2].attribute("aria-expanded")).to eq("false")

      ###################################################################
      # home and end select first and last block without opening any blocks
      driver.action.send_keys(:home).perform
      expect(page_block.attribute("aria-selected")).to eq("true")

      driver.action.send_keys(:end).perform
      expect(group_blocks[2].attribute("aria-selected")).to eq("true")

      ###################################################################
      # left arrow walks up the tree, closing groups as it goes
      driver.action.send_keys(:arrow_left).perform
      # select the 2nd column's parent, the columns section
      expect(columns_section.attribute("aria-selected")).to eq("true")
      expect(columns_section.attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_left).perform
      # close the columns section
      expect(columns_section.attribute("aria-selected")).to eq("true")
      expect(columns_section.attribute("aria-expanded")).to eq("false")

      driver.action.send_keys(:arrow_left).perform
      # select the page block
      expect(page_block.attribute("aria-selected")).to eq("true")
    end

    it "should navigate past an empty open group" do
      driver.action.send_keys(:arrow_down).perform
      driver.action.send_keys(:arrow_right).perform
      driver.action.send_keys(:arrow_down).perform
      driver.action.send_keys(:arrow_down).perform
      driver.action.send_keys(:arrow_right).perform
      driver.action.send_keys(:arrow_down).perform
      driver.action.send_keys(:arrow_down).perform
      driver.action.send_keys(:arrow_right).perform
      # empty group is nowopen
      expect(group_blocks[3].attribute("aria-selected")).to eq("true")
      expect(group_blocks[3].attribute("aria-expanded")).to eq("true")

      driver.action.send_keys(:arrow_down).perform
      # alarm icon after the empty group
      expect(icon_block_titles[5].attribute("innerHTML")).to eq("alarm")
      driver.action.send_keys(:arrow_up).perform
      driver.action.send_keys(:arrow_up).perform
      # idea icon before the empty group
      expect(icon_block_titles[4].attribute("innerHTML")).to eq("idea")
      driver.action.send_keys(:arrow_down).perform
      driver.action.send_keys(:arrow_down).perform
      # alarm icon after the empty group
      expect(icon_block_titles[5].attribute("innerHTML")).to eq("alarm")
    end

    describe "block toolbar navigation" do
      it "should navigate the block toolbar with arrow keys" do
        # first, select a block
        icon_block.click
        expect(block_toolbar).to be_displayed
        expect(active_element).to eq(icon_block)

        kb_focus_block_toolbar
        expect(active_element.attribute("textContent")).to eq("Go up")

        driver.action.send_keys(:arrow_down).perform
        driver.action.send_keys(:arrow_right).perform
        driver.action.send_keys(:arrow_right).perform
        driver.action.send_keys(:arrow_right).perform
        driver.action.send_keys(:arrow_right).perform
        expect(active_element.attribute("textContent")).to eq("Delete")

        # one more and it wraps around
        driver.action.send_keys(:arrow_right).perform
        expect(active_element.attribute("textContent")).to eq("Go up")

        # back up
        driver.action.send_keys(:arrow_up).perform
        expect(active_element.attribute("textContent")).to eq("Delete")
      end

      it "should refocus block toolbar with escape" do
        # first, select a block
        icon_block.click
        expect(block_toolbar).to be_displayed

        kb_focus_block_toolbar
        expect_block_toolbar_menu(block_toolbar_menus[:icon])

        driver.action.send_keys(:escape).perform
        expect(active_element).to eq(icon_block)
      end

      it "can resize blocks with the keyboard" do
        open_block_toolbox_to_tab("blocks")
        drop_new_block("group", group_block_dropzone)
        expect(group_block_child).to be_displayed
        group_block_child.click
        expect(block_toolbar).to be_displayed
        expect(block_resize_handle("se")).to be_displayed
        h = group_block_child.size.height
        w = group_block_child.size.width
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
        body.send_keys(:alt, :arrow_down)
        h += 1
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
        body.send_keys(:alt, :arrow_right)
        w += 1
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
        body.send_keys(:alt, :arrow_left)
        w -= 1
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
        body.send_keys(:alt, :arrow_up)
        h -= 1
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
        body.send_keys(:alt, :shift, :arrow_right)
        w += 10
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
        body.send_keys(:alt, :shift, :arrow_down)
        h += 10
        expect(group_block_child.size.height).to eq(h)
        expect(group_block_child.size.width).to eq(w)
      end

      describe("IconBlock's Select Icon button") do
        it "should navigate the icons using the arrow keys" do
          icon_block.click
          expect(block_toolbar).to be_displayed
          expect(active_element).to eq(icon_block)

          kb_focus_block_toolbar
          expect(active_element.attribute("textContent")).to eq("Go up")

          driver.action.send_keys(:arrow_right).perform
          driver.action.send_keys(:arrow_right).perform
          driver.action.send_keys(:arrow_right).perform
          expect(active_element.attribute("textContent")).to eq("Select Icon")

          # open the icon picker
          driver.action.send_keys(:enter).perform
          expect(select_an_icon_popup).to be_displayed
          expect(active_element.attribute("textContent").gsub(/\s+/, "")).to eq("alarm")

          # navigate the icons
          driver.action.send_keys(:arrow_down).perform
          expect(active_element.attribute("textContent").gsub(/\s+/, "")).to eq("apple")

          driver.action.send_keys(:arrow_right).perform
          expect(active_element.attribute("textContent").gsub(/\s+/, "")).to eq("atom")

          driver.action.send_keys(:enter).perform
          expect(active_element.attribute("textContent")).to eq("Select Icon")

          expect(icon_block_title.attribute("textContent")).to eq("atom")
        end
      end
    end

    describe "block navigation" do
      describe("Right arrow") do
        it "should open the block; focus does not move when focus is on a closed block" do
          element[:great_grandparent].click
          driver.action.send_keys(:arrow_right).perform
          # open grandparent block
          expect(element[:grandparent].attribute("aria-selected")).to eq("true")
          expect(element[:grandparent].attribute("aria-expanded")).to eq("true")
        end

        it "should move focus to the first child block with right arrow when focus is on an open block" do
          element[:grandparent].click
          driver.action.send_keys(:arrow_right).perform
          # open grandparent block
          driver.action.send_keys(:arrow_right).perform
          expect(element[:grandparent].attribute("aria-selected")).to eq("false")
          expect(element[:parent_four_apples].attribute("aria-selected")).to eq("true")
          expect(element[:parent_four_apples].attribute("aria-expanded")).to eq("false")
        end
      end

      describe("Down arrow") do
        it "should move focus to the next block without opening or closing a block" do
          element[:child_icon_block].click
          driver.action.send_keys(:arrow_down).perform
          expect(element[:child_icon_block].attribute("aria-selected")).to eq("false")
          expect(element[:child_two_apples].attribute("aria-selected")).to eq("true")
        end
      end

      describe("Left arrow") do
        it "should close the block when focus is on an open block" do
          element[:great_grandparent].click
          driver.action.send_keys(:arrow_right).perform
          # open grandparent block
          driver.action.send_keys(:arrow_left).perform
          expect(element[:grandparent].attribute("aria-selected")).to eq("true")
          expect(element[:grandparent].attribute("aria-expanded")).to eq("false")
        end

        it "should move focus to its parent block when focus is on a child block that is also either an end block or a closed block" do
          element[:child_icon_block].click
          driver.action.send_keys(:arrow_left).perform
          expect(element[:child_icon_block].attribute("aria-selected")).to eq("false")
          expect(element[:parent_four_apples].attribute("aria-selected")).to eq("true")
          expect(element[:parent_four_apples].attribute("aria-expanded")).to eq("false")
        end

        it "should do nothing when focus is the PageBlock (the ROOT)" do
          element[:great_grandparent].click
          driver.action.send_keys(:arrow_left).perform
          expect(element[:great_grandparent].attribute("aria-selected")).to eq("true")
          expect(element[:great_grandparent].attribute("aria-expanded")).to eq("true")
        end
      end

      describe("Up arrow") do
        it "should move focus to the previous block without opening or closing a block" do
          element[:child_two_apples].click
          driver.action.send_keys(:arrow_up).perform
          expect(element[:child_two_apples].attribute("aria-selected")).to eq("false")
          expect(element[:child_icon_block].attribute("aria-selected")).to eq("true")
        end
      end

      describe("Home") do
        it "should move focus to the to the PageBlock" do
          element[:child_two_apples].click
          driver.action.send_keys(:home).perform
          expect(element[:child_two_apples].attribute("aria-selected")).to eq("false")
          expect(element[:great_grandparent].attribute("aria-selected")).to eq("true")
        end
      end

      describe("End") do
        it "should move focus to the last section" do
          element[:child_two_apples].click
          driver.action.send_keys(:end).perform
          expect(element[:child_two_apples].attribute("aria-selected")).to eq("false")
          expect(element[:parent_idea_with_alarm_icons].attribute("aria-selected")).to eq("true")
        end
      end

      describe("Enter") do
        it "should select an unselected block" do
          element[:child_two_apples].click
          driver.action.send_keys(:enter).perform
          expect(element[:child_two_apples].attribute("aria-selected")).to eq("true")
          expect(element[:child_two_apples].attribute("aria-expanded")).to eq("false")
        end

        it "should open the text block modal when focus is on a text block" do
          element[:child_two_apples].click
          driver.action.send_keys(:arrow_right).perform
          driver.action.send_keys(:arrow_right).perform
          driver.action.send_keys(:arrow_down).perform
          driver.action.send_keys(:arrow_down).perform
          driver.action.send_keys(:enter).perform
          expect(text_block_popup).to be_displayed
        end
      end

      describe("Escape") do
        it "should unselect the selected block" do
          element[:child_two_apples].click
          driver.action.send_keys(:escape).perform
          expect(element[:child_two_apples].attribute("aria-selected")).to eq("false")
          expect(element[:great_grandparent].attribute("aria-selected")).to eq("true")
          expect(element[:great_grandparent].attribute("aria-expanded")).to eq("true")
        end
      end
    end

    describe "keyboard shortcuts" do
      it "should focus the block toolbar on ctrl-F9" do
        # first, select a block
        icon_block.click
        expect(block_toolbar).to be_displayed
        expect(active_element).to eq(icon_block)

        kb_focus_block_toolbar
        expect(active_element).to eq(f("button", block_toolbar))
      end

      it "should focus the topbar on alt-F10" do
        # first, select a block
        icon_block.click
        expect(block_toolbar).to be_displayed

        driver.action.key_down(:alt).send_keys(:f10).key_up(:alt).perform
        expect(active_element).to eq(topbar)
      end

      it "should focus the page with escape" do
        icon_block.click
        expect(block_toolbar).to be_displayed

        driver.action.send_keys(:escape).perform
        expect(active_element).to eq(page_block)
      end
    end
  end
end
