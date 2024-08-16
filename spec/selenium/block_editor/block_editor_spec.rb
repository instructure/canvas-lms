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

#
# some if the specs in here include "ignore_js_errors: true". This is because
# console errors are emitted for things that aren't really errors, like react
# jsx attribute type warnings
#

# rubocop:disable Specs/NoNoSuchElementError, Specs/NoExecuteScript
require_relative "../common"
require_relative "pages/block_editor_page"

describe "Block Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage

  let(:block_page_content) do
    '{
  "ROOT": {
    "type": {
      "resolvedName": "PageBlock"
    },
    "isCanvas": true,
    "props": {},
    "displayName": "Page",
    "custom": {},
    "hidden": false,
    "nodes": [
      "UO_WRGQgSQ"
    ],
    "linkedNodes": {}
  },
  "UO_WRGQgSQ": {
    "type": {
      "resolvedName": "BlankSection"
    },
    "isCanvas": false,
    "props": {},
    "displayName": "Blank Section",
    "custom": {
      "isSection": true
    },
    "parent": "ROOT",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "blank-section_nosection1": "e33NpD3Ck3"
    }
  },
  "e33NpD3Ck3": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "className": "blank-section__inner"
    },
    "displayName": "NoSections",
    "custom": {
      "noToolbar": true
    },
    "parent": "UO_WRGQgSQ",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}'
  end

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @context = @course
    @rce_page = @course.wiki_pages.create!(title: "RCE Page", body: "RCE Page Body")
    @block_page = @course.wiki_pages.create!(title: "Block Page")

    @block_page.update!(
      block_editor_attributes: {
        time: Time.now.to_i,
        version: "1",
        blocks: [
          {
            data: block_page_content
          }
        ]
      }
    )
  end

  def create_wiki_page(course)
    get "/courses/#{course.id}/pages"
    f("a.new_page").click
    wait_for_block_editor
  end

  context "Create new page" do
    before do
      create_wiki_page(@course)
    end

    context "Start from Scratch" do
      it "walks through the stepper" do
        expect(stepper_modal).to be_displayed
        stepper_start_from_scratch.click
        stepper_next_button.click
        expect(stepper_select_page_sections).to be_displayed
        stepper_hero_section_checkbox.click
        stepper_next_button.click
        expect(stepper_select_color_palette).to be_displayed
        stepper_next_button.click
        expect(stepper_select_font_pirings).to be_displayed
        stepper_start_creating_button.click
        expect(f("body")).not_to contain_css(stepper_modal_selector)
        expect(f(".hero-section")).to be_displayed
      end
    end

    context "Start from Template" do
      it "walks through the stepper" do
        expect(stepper_modal).to be_displayed
        stepper_start_from_template.click
        stepper_next_button.click
        f("#template-1").click
        stepper_start_editing_button.click
        expect(f("body")).not_to contain_css(stepper_modal_selector)
        expect(f(".hero-section")).to be_displayed
      end
    end
  end

  context "Edit a page" do
    it "edits an rce page with the rce" do
      get "/courses/#{@course.id}/pages/#{@rce_page.url}/edit"
      wait_for_rce
      expect(f("textarea.body").attribute("value")).to eq("<p>RCE Page Body</p>")
    end

    it "edits a block page with the block editor" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(f(".page-block")).to be_displayed
    end

    it "can drag and drop blocks from the toolbox" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      block_toolbox_toggle.click
      expect(block_toolbox).to be_displayed
      drag_and_drop_element(f(".toolbox-item.item-button"), f(".blank-section__inner"))
      expect(fj(".blank-section a:contains('Click me')")).to be_displayed
    end

    it "can resize blocks with the mouse" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      block_toolbox_toggle.click
      drag_and_drop_element(f(".toolbox-item.item-image"), f(".blank-section__inner"))
      f(".block.image-block").click  # select the section
      f(".block.image-block").click  # select the block
      expect(block_toolbar).to be_displayed
      click_block_toolbar_menu_item("Constraint", "Cover")

      expect(block_resize_handle_se).to be_displayed
      expect(f(".block.image-block").size.height).to eq(100)
      expect(f(".block.image-block").size.width).to eq(100)

      drag_and_drop_element_by(block_resize_handle_se, 100, 0)
      drag_and_drop_element_by(block_resize_handle_se, 0, 50)
      expect(f(".block.image-block").size.width).to eq(200)
      expect(f(".block.image-block").size.height).to eq(150)
    end

    it "can resize blocks with the keyboard" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      block_toolbox_toggle.click
      drag_and_drop_element(f(".toolbox-item.item-image"), f(".blank-section__inner"))
      f(".block.image-block").click  # select the section
      f(".block.image-block").click  # select the block
      expect(block_toolbar).to be_displayed
      click_block_toolbar_menu_item("Constraint", "Cover")

      expect(block_resize_handle_se).to be_displayed
      expect(f(".block.image-block").size.height).to eq(100)
      expect(f(".block.image-block").size.width).to eq(100)

      f("body").send_keys(:alt, :arrow_down)
      expect(f(".block.image-block").size.height).to eq(101)
      expect(f(".block.image-block").size.width).to eq(100)

      f("body").send_keys(:alt, :arrow_right)
      expect(f(".block.image-block").size.height).to eq(101)
      expect(f(".block.image-block").size.width).to eq(101)

      f("body").send_keys(:alt, :arrow_left)
      expect(f(".block.image-block").size.height).to eq(101)
      expect(f(".block.image-block").size.width).to eq(100)

      f("body").send_keys(:alt, :arrow_up)
      expect(f(".block.image-block").size.height).to eq(100)
      expect(f(".block.image-block").size.width).to eq(100)

      f("body").send_keys(:alt, :shift, :arrow_right)
      expect(f(".block.image-block").size.height).to eq(100)
      expect(f(".block.image-block").size.width).to eq(110)

      f("body").send_keys(:alt, :shift, :arrow_down)
      expect(f(".block.image-block").size.height).to eq(110)
      expect(f(".block.image-block").size.width).to eq(110)
    end
  end

  describe("resizing images that maintain aspect ratio") do
    before do
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(context: @course)
      path = File.expand_path(File.dirname(__FILE__) + "/../../fixtures/block-editor/white-sands.jpg")
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!
      # image is 2000w x 1000h

      @block_page.update!(
        block_editor_attributes: {
          time: Time.now.to_i,
          version: "1",
          blocks: [
            {
              data: "{\"ROOT\":{\"type\":{\"resolvedName\":\"PageBlock\"},\"isCanvas\":true,\"props\":{},\"displayName\":\"Page\",\"custom\":{},\"hidden\":false,\"nodes\":[\"AcfL3KeXTT\"],\"linkedNodes\":{}},\"AcfL3KeXTT\":{\"type\":{\"resolvedName\":\"BlankSection\"},\"isCanvas\":false,\"props\":{},\"displayName\":\"Blank Section\",\"custom\":{\"isSection\":true},\"parent\":\"ROOT\",\"hidden\":false,\"nodes\":[],\"linkedNodes\":{\"blank-section_nosection1\":\"0ZWqBwA2Ou\"}},\"0ZWqBwA2Ou\":{\"type\":{\"resolvedName\":\"NoSections\"},\"isCanvas\":true,\"props\":{\"className\":\"blank-section__inner\"},\"displayName\":\"NoSections\",\"custom\":{\"noToolbar\":true},\"parent\":\"AcfL3KeXTT\",\"hidden\":false,\"nodes\":[\"lLVSJCBPWm\"],\"linkedNodes\":{}},\"lLVSJCBPWm\":{\"type\":{\"resolvedName\":\"ImageBlock\"},\"isCanvas\":false,\"props\":{\"src\":\"/courses/#{@course.id}/files/#{@image.id}/preview\",\"variant\":\"default\",\"constraint\":\"cover\",\"maintainAspectRatio\":true,\"width\":100,\"height\":50},\"displayName\":\"Image\",\"custom\":{\"isResizable\":true},\"parent\":\"0ZWqBwA2Ou\",\"hidden\":false,\"nodes\":[],\"linkedNodes\":{}}}"
            }
          ]
        }
      )
    end

    it "adjusts the width when the height is changed" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      f(".block.image-block").click  # select the section
      f(".block.image-block").click  # select the block
      expect(block_resize_handle_se).to be_displayed
      expect(f(".block.image-block").size.width).to eq(100)
      expect(f(".block.image-block").size.height).to eq(50)

      drag_and_drop_element_by(block_resize_handle_se, 10, 50)
      expect(f(".block.image-block").size.width).to eq(200)
      expect(f(".block.image-block").size.height).to eq(100)
    end
  end
end

# rubocop:enable Specs/NoNoSuchElementError, Specs/NoExecuteScript
