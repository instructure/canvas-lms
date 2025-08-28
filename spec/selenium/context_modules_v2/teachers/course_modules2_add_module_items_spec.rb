# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules2_index_page"
require_relative "../page_objects/modules2_action_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"

describe "selective_release module item assign to tray", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  def open_assign_to_tray_for(item_id)
    module_header_expand_toggles.first.click
    manage_module_item_button(item_id).click
    click_manage_module_item_assign_to
  end

  before(:once) do
    course_with_teacher(active_all: true)
    set_rewrite_flag
    @course.enable_feature! :quizzes_next
    @course.context_external_tools.create!(
      name: "Quizzes.Next",
      consumer_key: "test_key",
      shared_secret: "test_secret",
      tool_id: "Quizzes 2",
      url: "http://example.com/launch"
    )
    @course.root_account.settings[:provision] = { "lti" => "lti url" }
    @course.root_account.save!
  end

  context "add module items with modal", :ignore_js_errors do
    before(:once) do
      @module = @course.context_modules.create!(name: "module1")
      @assignment = @course.assignments.create!(
        name: "Assignment 1",
        submission_types: "online_text_entry",
        points_possible: 10,
        workflow_state: "published"
      )
    end

    before do
      user_session(@teacher)
    end

    it "adds an assignment to the module" do
      go_to_modules

      add_item_button(@module.id).click
      click_INSTUI_Select_option(add_existing_item_select_selector, "Assignment 1")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment.id)

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "adds a quiz to the module" do
      @quiz = @course.quizzes.create!(title: "Quiz 1")

      go_to_modules

      add_item_button(@module.id).click

      click_INSTUI_Select_option(new_item_type_select_selector, "Quiz")
      wait_for_ajaximations

      click_INSTUI_Select_option(add_existing_item_select_selector, "Quiz 1")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Quizzes::Quiz", content_id: @quiz.id)

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "adds a wiki page to the module" do
      @wiki_page = @course.wiki_pages.create!(title: "Wiki Page 1", body: "This is a wiki page.")

      go_to_modules

      add_item_button(@module.id).click

      click_INSTUI_Select_option(new_item_type_select_selector, "Page")
      wait_for_ajaximations

      click_INSTUI_Select_option(add_existing_item_select_selector, "Wiki Page 1")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "WikiPage", content_id: @wiki_page.id)

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "adds a discussion topic to the module" do
      @discussion_topic = @course.discussion_topics.create!(title: "Discussion Topic 1", message: "This is a discussion topic.")

      go_to_modules

      add_item_button(@module.id).click

      click_INSTUI_Select_option(new_item_type_select_selector, "Discussion")
      wait_for_ajaximations

      click_INSTUI_Select_option(add_existing_item_select_selector, "Discussion Topic 1")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "DiscussionTopic", content_id: @discussion_topic.id)

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "adds a text header to the module" do
      go_to_modules

      add_item_button(@module.id).click

      click_INSTUI_Select_option(new_item_type_select_selector, "Text Header")

      input_text_in_text_header_input("Text Header 1")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "ContextModuleSubHeader", title: "Text Header 1")

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "adds an external URL to the module" do
      go_to_modules

      add_item_button(@module.id).click

      click_INSTUI_Select_option(new_item_type_select_selector, "External URL")
      wait_for_ajaximations

      input_text_in_url_input("https://www.google.com")
      input_text_in_url_title_input("External URL 1")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "ExternalUrl", title: "External URL 1")

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "adds a file to the module" do
      @file = @course.attachments.create!(display_name: "file", uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
      @file.context = @course
      @file.save!

      go_to_modules

      add_item_button(@module.id).click

      click_INSTUI_Select_option(new_item_type_select_selector, "File")
      wait_for_ajaximations

      click_INSTUI_Select_option(add_existing_item_select_selector, "file")
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Attachment", content_id: @file.id)

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end

    it "allows adding an external tool to the module" do
      @external_tool = @course.context_external_tools.create!(
        context_id: @course.id,
        context_type: "Course",
        url: "https://example.com",
        shared_secret: "fake",
        consumer_key: "fake",
        name: "Test External Tool",
        description: "An external tool for testing",
        settings: { "platform" => "canvas.instructure.com" },
        workflow_state: "active"
      )

      go_to_modules
      wait_for_ajaximations

      add_item_button(@module.id).click
      wait_for_ajaximations

      # Select External Tool from the dropdown
      click_INSTUI_Select_option(new_item_type_select_selector, "External Tool")
      wait_for_ajaximations

      # Select external tool from the dropdown
      click_INSTUI_Select_option(add_existing_item_select_selector, @external_tool.name)
      wait_for_ajaximations

      new_item_name = "External Tool Page Name"

      replace_content(external_tool_page_name_input, new_item_name)

      # Click Add Item
      add_item_modal_add_item_button.click

      module_item = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "ContextExternalTool", content_id: @external_tool.id)

      module_header_expand_toggles.first.click

      expect(element_exists?(context_module_item_selector(module_item.id))).to be true
    end
  end
end
