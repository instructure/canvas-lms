# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../helpers/context_modules_common"
require_relative "../helpers/public_courses_context"
require_relative "page_objects/modules_index_page"
require_relative "page_objects/modules_settings_tray"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray

  context "as a teacher through course home page (set to modules)", priority: "1" do
    before(:once) do
      course_with_teacher(name: "teacher", active_all: true)
    end

    context "when adding new module" do
      before do
        user_session(@teacher)
        get "/courses/#{@course.id}"
      end

      it "renders as course home page", priority: "1" do
        create_modules(1)
        @course.default_view = "modules"
        @course.save!
        get "/courses/#{@course.id}"
        expect(f(".add_module_link").text).not_to be_nil
      end
    end

    context "when working with existing module" do
      before :once do
        @new_module = @course.context_modules.create! name: "New Module"
      end

      before do
        user_session(@teacher)
        get "/courses/#{@course.id}"
        wait_for_modules_ui
      end

      it "unpublishes a published module", priority: "1" do
        mod = @course.context_modules.first
        expect(mod).to be_published
        unpublish_module_and_items(mod.id)
        mod.reload
        expect(mod).to be_unpublished
      end

      it "keeps module workflow state after editing module", priority: "1" do
        edit_text = "New Module Name"
        mod = @course.context_modules.first
        mod.workflow_state = "unpublished"
        mod.save!
        go_to_modules
        expect(unpublished_module_icon(mod.id)).to be_present
        publish_module_and_items(mod.id)
        expect(published_module_icon(mod.id)).to be_present
        manage_module_button(mod).click
        module_index_menu_tool_link("Edit").click
        expect(settings_tray_exists?).to be_truthy
        update_module_name(edit_text)
        click_settings_tray_update_module_button
        expect(settings_tray_exists?).to be_falsey
        expect(ff(".context_module > .header")[0]).to include_text(edit_text)
        expect(published_module_icon(mod.id)).to be_present
      end

      it "deletes a module", priority: "1" do
        skip_if_safari(:alert)
        f(".ig-header-admin .al-trigger").click
        f(".delete_module_link").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        refresh_page
        expect(f("#no_context_modules_message")).to be_displayed
        expect(f(".context_module > .header")).not_to be_displayed
      end

      it "adds an assignment to a module", priority: "1" do
        add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
        expect(fln("New Assignment Title")).to be_displayed
      end

      it "validate only one assignment is created when multiple clicks are done", priority: "2" do
        first_module = @course.context_modules.reload.first
        add_module_item_button(first_module).click
        f("#add_module_item_select").click
        select_module_item("#assignments_select" + " .module_item_select", "[ Create Assignment ]")
        replace_content(f("#assignments_select input.item_title"), "New Assignment Title")
        driver.action.double_click(f(".add_item_button.ui-button")).perform
        wait_for_ajax_requests
        expect(@course.assignments.where(title: "New Assignment Title").count).to eq 1
      end

      it "adds a assignment item to a module, publish new assignment refresh page and verify", priority: "2" do
        # this test basically verifies that the published icon is accurate after a page refresh
        mod = @course.context_modules.first
        assignment = @course.assignments.create!(title: "assignment 1")
        assignment.unpublish!
        tag = mod.add_item({ id: assignment.id, type: "assignment" })
        refresh_page
        item = f("#context_module_item_#{tag.id}")
        expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
        item.find_element(:css, ".publish-icon").click
        wait_for_ajax_requests
        expect(tag.reload).to be_published
        refresh_page
        f("#course_publish_button button").click
        f("div[role='menu'][aria-label='course_publish_menu'] button:not([aria-disabled])").click
        expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
        expect(tag).to be_published
      end

      it "adds a quiz to a module", priority: "1" do
        mod = @course.context_modules.first
        quiz = @course.quizzes.create!(title: "New Quiz Title")
        mod.add_item({ id: quiz.id, type: "quiz" })
        refresh_page
        verify_persistence("New Quiz Title")
      end

      it "adds a content page item to a module", priority: "1" do
        mod = @course.context_modules.first
        page = @course.wiki_pages.create!(title: "New Page Title")
        mod.add_item({ id: page.id, type: "wiki_page" })
        refresh_page
        verify_persistence("New Page Title")
      end

      it "adds a content page item to a module and publish new page", priority: "2" do
        mod = @course.context_modules.first
        page = @course.wiki_pages.create!(title: "PAGE 2")
        page.unpublish!
        tag = mod.add_item({ id: page.id, type: "wiki_page" })
        refresh_page
        item = f("#context_module_item_#{tag.id}")
        expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
        item.find_element(:css, ".publish-icon").click
        wait_for_ajax_requests
        expect(tag.reload).to be_published
      end
    end

    context "when adding new module with differentiated modules" do
      before :once do
        @new_module = @course.context_modules.create! name: "New Module"
      end

      before do
        user_session(@teacher)
        get "/courses/#{@course.id}"
      end

      it "adds a new module with differentiated modules", priority: "1" do
        add_module_with_tray("New Module2")
        mod = @course.context_modules.last
        expect(mod.name).to eq "New Module2"
      end

      it "publishes an unpublished module with differentiated modules", priority: "1" do
        add_module_with_tray("New Module2")
        expect(ff(".context_module")[1]).to have_class("unpublished_module")
        expect(@course.context_modules.count).to eq 2
        mod = @course.context_modules.last
        expect(mod.name).to eq "New Module2"
        publish_module_and_items(mod.id)
        mod.reload
        expect(mod).to be_published
        expect(published_module_icon(mod.id)).to be_displayed
      end

      it "edits a module with differentiated modules", priority: "1" do
        edit_text = "Module Edited"
        manage_module_button(@new_module).click
        module_index_menu_tool_link("Edit").click
        expect(settings_tray_exists?).to be_truthy
        update_module_name(edit_text)
        click_settings_tray_update_module_button
        expect(settings_tray_exists?).to be_falsey
        expect(ff(".context_module > .header")[0]).to include_text(edit_text)
      end
    end
  end
end
