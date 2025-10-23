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

require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules2_index_page"

describe "master courses - child courses - module item locking for React modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage

  context "in the child course" do
    before :once do
      @copy_from = course_factory(active_all: true)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      @original_page = @copy_from.wiki_pages.create!(title: "blah", body: "bloo")
      @page_mc_tag = @template.create_content_tag_for!(@original_page, restrictions: { content: true })

      @original_topic = @copy_from.discussion_topics.create!(title: "blah", message: "bloo")
      @topic_mc_tag = @template.create_content_tag_for!(@original_topic)

      course_with_teacher(active_all: true)
      @copy_to = @course
      @sub = @template.add_child_course!(@copy_to)

      @page_copy = @copy_to.wiki_pages.create!(title: "locked page", migration_id: @page_mc_tag.migration_id)
      @topic_copy = @copy_to.discussion_topics.create!(title: "unlocked topic", migration_id: @topic_mc_tag.migration_id)
      [@page_copy, @topic_copy].each { |obj| @sub.create_content_tag_for!(obj) }
      @assmt = @copy_to.assignments.create!(title: "normal assignment")

      @mod = @copy_to.context_modules.create!(name: "modle")
      @locked_tag = @mod.add_item(id: @page_copy.id, type: "wiki_page")
      @unlocked_tag = @mod.add_item(id: @topic_copy.id, type: "discussion_topic")
      @normal_tag = @mod.add_item(id: @assmt.id, type: "assignment")

      # Enable the React modules page
      set_rewrite_flag
    end

    before do
      user_session(@teacher)
    end

    def go_to_modules
      get "/courses/#{@copy_to.id}/modules"
      wait_for_ajaximations
    end

    it "shows all the icons on the modules index" do
      go_to_modules

      # Expand the module to see its items
      context_module_expand_toggle(@mod.id).click
      wait_for_ajaximations

      # Objects inherited from master show the lock
      expect(module_blueprint_lock_icon(@locked_tag.id, locked: true)).to be_displayed
      expect(module_blueprint_lock_icon(@unlocked_tag.id, locked: false)).to be_displayed

      # Objects added to the child do not have blueprint icons
      expect(f(module_item_by_id_selector(@normal_tag.id))).not_to contain_css(blueprint_lock_icon_selector(locked: true))
      expect(f(module_item_by_id_selector(@normal_tag.id))).not_to contain_css(blueprint_lock_icon_selector(locked: false))
    end

    it "disables the title edit input for locked items" do
      skip "2025-07-24 title input is not disabled: LX-2962"
      go_to_modules

      # Expand the module to see its items
      context_module_expand_toggle(@mod.id).click
      wait_for_ajaximations

      # Click the action menu for the locked item
      manage_module_item_button(@locked_tag.id).click
      module_item_action_menu_link("Edit").click
      wait_for_ajaximations

      # The title field should be disabled
      title_input = edit_item_modal.find_element(:css, "input[type=text]")
      expect(title_input).to be_disabled
    end

    it "does not disable the title edit input for unlocked items" do
      go_to_modules

      # Expand the module to see its items
      context_module_expand_toggle(@mod.id).click
      wait_for_ajaximations
      # Click the action menu for the unlocked item
      manage_module_item_button(@unlocked_tag.id).click
      module_item_action_menu_link("Edit").click
      wait_for_ajaximations

      # The title field should not be disabled
      title_input = edit_item_modal.find_element(:css, "input[type=text]")
      expect(title_input).not_to be_disabled
    end

    it "loads new restriction info as needed when adding an item" do
      title = "new quiz"
      original_quiz = @copy_from.quizzes.create!(title:)
      quiz_mc_tag = @template.create_content_tag_for!(original_quiz, restrictions: { content: true })

      quiz_copy = @copy_to.quizzes.create!(title:, migration_id: quiz_mc_tag.migration_id)
      @sub.create_content_tag_for!(quiz_copy)

      go_to_modules

      # Expand the module to see its items
      context_module_expand_toggle(@mod.id).click
      wait_for_ajaximations

      # Add the quiz to the module
      add_item_button(@mod.id).click
      wait_for_ajaximations

      # Select Quiz from the dropdown
      click_INSTUI_Select_option(new_item_type_select_selector, "Quiz")
      wait_for_ajaximations

      search_and_select_existing_item(title)
      add_item_modal_add_item_button.click
      wait_for_ajaximations

      # Find the new tag
      new_tag = ContentTag.last
      expect(new_tag.content).to eq quiz_copy

      # Check that it has the locked icon
      expect(module_blueprint_lock_icon(new_tag.id, locked: true)).to be_displayed
    end
  end

  context "in the master course" do
    before :once do
      @course = course_factory(active_all: true)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)

      @assmt = @course.assignments.create!(title: "assmt blah", description: "bloo")
      @assmt_tag = @template.create_content_tag_for!(@assmt)

      @page = @course.wiki_pages.create!(title: "page blah", body: "bloo")
      @page_tag = @template.create_content_tag_for!(@page, restrictions: { all: true })

      @topic = @course.discussion_topics.create!(title: "topic blah", message: "bloo")
      # NOTE: the lack of a content tag

      @mod = @course.context_modules.create!(name: "modle")
      @assmt_mod_tag = @mod.add_item(id: @assmt.id, type: "assignment")
      @page_mod_tag  = @mod.add_item(id: @page.id, type: "wiki_page")
      @topic_mod_tag = @mod.add_item(id: @topic.id, type: "discussion_topic")
      @header_tag = @mod.add_item(type: "context_module_sub_header", title: "header")

      # Enable the React modules page
      set_rewrite_flag
    end

    before do
      user_session(@teacher)
    end

    def go_to_modules
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations
    end

    it "shows all the icons on the modules index" do
      go_to_modules

      # Expand the module to see its items
      context_module_expand_toggle(@mod.id).click
      wait_for_ajaximations

      # Check for the appropriate icons
      expect(module_blueprint_lock_button(@assmt_mod_tag.id, locked: false)).to be_displayed
      expect(module_blueprint_lock_button(@page_mod_tag.id, locked: true)).to be_displayed

      # Should still have icon even without tag
      expect(module_blueprint_lock_button(@topic_mod_tag.id, locked: false)).to be_displayed

      # Header should not have blueprint icon
      expect(f(module_item_by_id_selector(@header_tag.id))).not_to contain_css(blueprint_lock_icon_selector(locked: true))
      expect(f(module_item_by_id_selector(@header_tag.id))).not_to contain_css(blueprint_lock_icon_selector(locked: false))
    end
  end
end
