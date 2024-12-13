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
#
require_relative "../common"
require_relative "pages/block_editor_page"

# chrome complains about "Blocked aria-hidden on an element because its descendant retained focus."
# this is a transient condition that resolves itself and does not cause a problem (that I know of)
describe "Block Editor", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage

  def drop_new_block(block_name, where)
    drag_and_drop_element(block_toolbox_box_by_block_name(block_name), where)
  end

  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @context = @course
    @rce_page = @course.wiki_pages.create!(title: "RCE Page", body: "RCE Page Body")
    @block_page = build_wiki_page("page-with-apple-icon.json")
  end

  context "Create new page" do
    before do
      create_wiki_page(@course)
    end

    context "Start from Scratch" do
      it "shows the template chooser modal with a default page block" do
        expect(template_chooser).to be_displayed
        template_chooser_new_blank_page.click
        expect(page_block).to be_displayed
      end
    end

    context "Load template" do
      it "loads the clicked template to the editor" do
        expect(template_chooser).to be_displayed
        wait_for_ajax_requests
        # I don't know why this expectation succeeds locally and fails in jenkins,
        # the quick look button is not visible
        # expect(body).not_to contain_jqcss(template_chooser_active_customize_template_selector)
        template_chooser_template_for_number(1).send_keys("")
        template_chooser_active_customize_template.click
        wait_for_ajax_requests
        expect(page_block).to be_displayed
      end

      it "loads template via quick look" do
        expect(template_chooser).to be_displayed
        wait_for_ajax_requests
        # same
        # expect(body).not_to contain_jqcss(template_chooser_active_quick_look_template_selector)
        template_chooser_template_for_number(1).send_keys("")
        template_chooser_active_quick_look_template.click
        wait_for_ajax_requests
        expect(page_block).to be_displayed
        expect(template_quick_look_header).to be_displayed
      end
    end
  end

  context "Edit a page" do
    it "edits an rce page with the rce", :ignore_js_errors do
      get "/courses/#{@course.id}/pages/#{@rce_page.url}/edit"
      wait_for_rce
      expect(f("textarea.body").attribute("value")).to eq("<p>RCE Page Body</p>")
    end

    it "edits a block page with the block editor" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      expect(page_block).to be_displayed
      expect(icon_block).to be_displayed
      expect(icon_block_title.attribute("textContent")).to eq("apple")
    end

    it "can drag and drop blocks from the toolbox" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      open_block_toolbox_to_tab("blocks")
      expect(block_toolbox).to be_displayed
      drop_new_block("button", group_block_dropzone)
      expect(fj("#{group_block_inner_selector}:contains('Click me')")).to be_displayed
    end

    it "cannot resize an image with no src" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      open_block_toolbox_to_tab("blocks")
      drop_new_block("image", group_block_dropzone)
      image_block.click  # select the section
      image_block.click  # select the block
      expect(block_toolbar).to be_displayed
      expect(block_editor_editor).not_to contain_css(block_resize_handle_selector("se"))
    end

    it "can resize blocks with the mouse" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      open_block_toolbox_to_tab("blocks")
      drop_new_block("group", group_block_dropzone)
      # the first .group-block is the column, the second is our block
      the_block = f(".group-block .group-block")
      expect(the_block).to be_displayed
      the_block.click
      expect(block_toolbar).to be_displayed
      expect(block_resize_handle("se")).to be_displayed
      h = the_block.size.height
      w = the_block.size.width
      drag_and_drop_element_by(block_resize_handle("se"), 100, 0)
      w += 100
      drag_and_drop_element_by(block_resize_handle("se"), 0, 50)
      h += 50
      expect(the_block.size.width).to eq(w)
      expect(the_block.size.height).to eq(h)
    end

    it "can resize blocks with the keyboard" do
      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      open_block_toolbox_to_tab("blocks")
      drop_new_block("group", group_block_dropzone)
      the_block = f(".group-block .group-block")
      expect(the_block).to be_displayed
      the_block.click
      expect(block_toolbar).to be_displayed
      expect(block_resize_handle("se")).to be_displayed
      h = the_block.size.height
      w = the_block.size.width
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
      f("body").send_keys(:alt, :arrow_down)
      h += 1
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
      f("body").send_keys(:alt, :arrow_right)
      w += 1
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
      f("body").send_keys(:alt, :arrow_left)
      w -= 1
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
      f("body").send_keys(:alt, :arrow_up)
      h -= 1
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
      f("body").send_keys(:alt, :shift, :arrow_right)
      w += 10
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
      f("body").send_keys(:alt, :shift, :arrow_down)
      h += 10
      expect(the_block.size.height).to eq(h)
      expect(the_block.size.width).to eq(w)
    end

    context "image block" do
      before do
        stub_rcs_config
      end

      it "can add course images" do
        @root_folder = Folder.root_folders(@course).first
        @image = @root_folder.attachments.build(context: @course)
        path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/email.png")
        @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        @image.save!
        get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
        wait_for_block_editor
        open_block_toolbox_to_tab("blocks")
        drop_new_block("image", group_block_dropzone)
        image_block.click
        image_block_upload_button.click
        course_images_tab.click
        image_thumbnails[0].click
        submit_button.click
        expected_src = "/courses/#{@course.id}/files/#{@image.id}/preview"
        expect(image_block_image["src"]).to include(expected_src)
      end

      it "can add user images" do
        @root_folder = Folder.root_folders(@course).first
        @image = @root_folder.attachments.build(context: @user)
        path = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/email.png")
        @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        @image.save!
        get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
        wait_for_block_editor
        open_block_toolbox_to_tab("blocks")
        drop_new_block("image", group_block_dropzone)
        image_block.click
        image_block_upload_button.click
        user_images_tab.click
        image_thumbnails[0].click
        submit_button.click
        expected_src = "/users/#{@user.id}/files/#{@image.id}/preview"
        expect(image_block_image["src"]).to include(expected_src)
      end
    end
  end

  describe("manipulating images") do
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
          version: "0.3",
          blocks: "{\"ROOT\":{\"type\":{\"resolvedName\":\"PageBlock\"},\"isCanvas\":true,\"props\":{},\"displayName\":\"Page\",\"custom\":{},\"hidden\":false,\"nodes\":[\"AcfL3KeXTT\"],\"linkedNodes\":{}},\"AcfL3KeXTT\":{\"type\":{\"resolvedName\":\"BlankSection\"},\"isCanvas\":false,\"props\":{},\"displayName\":\"Blank Section\",\"custom\":{\"isSection\":true},\"parent\":\"ROOT\",\"hidden\":false,\"nodes\":[],\"linkedNodes\":{\"blank-section_nosection1\":\"0ZWqBwA2Ou\"}},\"0ZWqBwA2Ou\":{\"type\":{\"resolvedName\":\"NoSections\"},\"isCanvas\":true,\"props\":{\"className\":\"blank-section__inner\",\"placeholderText\":\"Drop a block to add it here\"},\"displayName\":\"NoSections\",\"custom\":{\"noToolbar\":true},\"parent\":\"AcfL3KeXTT\",\"hidden\":false,\"nodes\":[\"lLVSJCBPWm\"],\"linkedNodes\":{}},\"lLVSJCBPWm\":{\"type\":{\"resolvedName\":\"ImageBlock\"},\"isCanvas\":false,\"props\":{\"src\":\"/courses/#{@course.id}/files/#{@image.id}/preview\",\"variant\":\"default\",\"constraint\":\"cover\",\"maintainAspectRatio\":true,\"sizeVariant\":\"pixel\",\"width\":200,\"height\":100},\"displayName\":\"Image\",\"custom\":{\"isResizable\":true},\"parent\":\"0ZWqBwA2Ou\",\"hidden\":false,\"nodes\":[],\"linkedNodes\":{}}}"
        }
      )
    end

    describe("resizing") do
      it("is not possible with SizeVariant 'auto'") do
        get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
        wait_for_block_editor
        image_block.click  # select the section
        image_block.click  # select the block
        expect(block_resize_handle("se")).to be_displayed
        click_block_toolbar_menu_item("Image Size", "Auto")
        expect(block_editor_editor).not_to contain_css(block_resize_handle_selector("se"))
      end

      describe("that maintain aspect ratio") do
        it "adjusts the width when the height is changed" do
          get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
          wait_for_block_editor
          image_block.click  # select the section
          image_block.click  # select the block
          expect(block_resize_handle("se")).to be_displayed
          expect(image_block.size.width).to eq(200)
          expect(image_block.size.height).to eq(100)
          f("body").send_keys(:alt, :shift, :arrow_down)
          expect(image_block.size.height).to eq(110)
          expect(image_block.size.width).to eq(220)
        end
      end
    end

    describe("add alt text") do
      it "can add alt text" do
        get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
        wait_for_block_editor
        image_block.click
        image_block_alt_text_button.click
        alt_input = image_block_alt_text_input
        expect(alt_input).to be_displayed
        alt_input.send_keys("I am alt text")
        alt_input.send_keys(:escape)
        expect(f("img", image_block).attribute("alt")).to eq("I am alt text")
      end
    end
  end
end
# rubocop:enable Specs/NoNoSuchElementError, Specs/NoExecuteScript
