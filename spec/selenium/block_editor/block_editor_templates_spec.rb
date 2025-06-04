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

# NOTE: for these tests to work, our user needs to be in a role with
# Block Editor Templates - edit or Block Editor Global Templates - edit permissions
# I don't have time for that atm, so this is just a stub of a test file

require_relative "../common"
require_relative "pages/block_editor_page"
describe "Block Editor templates", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include BlockEditorPage
  def drop_new_block(block_name, where)
    drag_and_drop_element(block_toolbox_box_by_block_name(block_name), where)
  end
  before do
    course_with_teacher_logged_in
    @course.account.enable_feature!(:block_editor)
    @course.account.enable_feature!(:block_template_editor)
    @context = @course
    @block_page = build_wiki_page("page-with-apple-icon.json")
  end

  context "as a template editor" do
    before do
      account_admin_user_with_role_changes(role_changes: { block_editor_template_editor: true,
                                                           block_editor_global_template_editor: false })
      user_session(@user)

      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      click_and_check(icon_block, block_toolbar_selector("go-up"))
      block_toolbar_action("go-up").click
    end

    it "can save a block template" do
      block_toolbar_action("save-template").click
      expect(edit_template_modal_text_input_template_name).to be_displayed
      edit_template_modal_text_input_template_name.send_keys("block template")
      edit_template_modal_text_area_template_description.send_keys("can save a block template")
      edit_template_modal_button_save.click
      open_block_toolbox_to_tab("blocks")
      expect(blocks_panel_view_item_template_block.text).to include("block template")
    end

    it "can save a section template" do
      block_toolbar_action("go-up").click
      block_toolbar_action("save-template").click
      expect(edit_template_modal_text_input_template_name).to be_displayed
      edit_template_modal_text_input_template_name.send_keys("section template")
      edit_template_modal_text_area_template_description.send_keys("can save a section template")
      edit_template_modal_button_save.click
      open_block_toolbox_to_tab("sections")
      expect(edit_block_toolbox_sections_list.text).to include("section template")
      expect(edit_block_toolbox_sections_list.text).to include("can save a section template")
    end

    it "can't save a page template" do
      block_toolbar_action("go-up").click
      expect_block_toolbar_menu(block_toolbar_menus_editor_privileges[:columns])
    end

    it "can publish an unpublished block template" do
      block_toolbar_action("save-template").click
      edit_template_modal_text_input_template_name.send_keys("block template")
      edit_template_modal_text_area_template_description.send_keys("can save a block template")
      edit_template_modal_checkbox_published.click
      edit_template_modal_button_save.click
      open_block_toolbox_to_tab("blocks")
      toolbox_template_block_action("edit").click
      edit_template_modal_checkbox_published.click
      edit_template_modal_button_save.click
      expect(blocks_panel_view_item_template_block.css_value("border-color")).to eq("rgb(207, 74, 0)"), "Expected border color to be red:" + blocks_panel_view_item_template_block.css_value("border-color")
    end

    it "can unpublish a published block template" do
      block_toolbar_action("save-template").click
      edit_template_modal_text_input_template_name.send_keys("block template")
      edit_template_modal_text_area_template_description.send_keys("can save a block template")
      edit_template_modal_button_save.click
      open_block_toolbox_to_tab("blocks")
      toolbox_template_block_action("edit").click
      edit_template_modal_checkbox_published.click
      edit_template_modal_button_save.click
      expect(blocks_panel_view_item_template_block.css_value("border-color")).to eq("rgb(215, 218, 222)"), "Expected border color to be gray:" + blocks_panel_view_item_template_block.css_value("border-color")
    end

    it "can edit a block template's name" do
      block_toolbar_action("save-template").click
      edit_template_modal_text_input_template_name.send_keys("block template")
      edit_template_modal_text_area_template_description.send_keys("can save a block template")
      edit_template_modal_button_save.click
      open_block_toolbox_to_tab("blocks")
      toolbox_template_block_action("edit").click
      edit_template_modal_text_input_template_name.send_keys(" updated")
      edit_template_modal_button_save.click
      expect(blocks_panel_view_item_template_block.text).to include("block template updated"), "Expected the text to include 'block template updated'"
    end
  end

  context "as a global template editor" do
    before do
      account_admin_user_with_role_changes(role_changes: { block_editor_template_editor: true,
                                                           block_editor_global_template_editor: true })
      user_session(@user)

      get "/courses/#{@course.id}/pages/#{@block_page.url}/edit"
      wait_for_block_editor
      click_and_check(icon_block, block_toolbar_selector("go-up"))
      block_toolbar_action("go-up").click
      block_toolbar_action("go-up").click
    end

    it "can create a global section template" do
      block_toolbar_action("save-template").click
      edit_template_modal_text_input_template_name.send_keys("global section")
      edit_template_modal_text_area_template_description.send_keys("create a global section template")
      edit_template_modal_checkbox_global_template.click
      edit_template_modal_button_save.click
      icon_block.click
      navigate_to_downloads
      expect(body.text).to match(/template-.*\.json/)
    end

    it "can create a global page template" do
      block_toolbar_action("go-up").click
      block_toolbar_action("save-template").click
      edit_template_modal_text_input_template_name.send_keys("global page template")
      edit_template_modal_text_area_template_description.send_keys("can create a global page")
      edit_template_modal_checkbox_global_template.click
      edit_template_modal_button_save.click
      icon_block.click
      navigate_to_downloads
      expect(body.text).to match(/template-.*\.json/)
    end
  end
end
