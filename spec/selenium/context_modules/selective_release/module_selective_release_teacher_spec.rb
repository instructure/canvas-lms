# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"

describe "selective_release module set up" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray

  context "using tray to update settings" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      module_setup
    end

    before do
      user_session(@teacher)
    end

    it "accesses the modules tray for a module and closes" do
      go_to_modules
      manage_module_button(@module).click

      # maybe should use a settings option when available
      module_index_menu_tool_link("Assign To...").click

      click_settings_tray_close_button

      expect(settings_tray_exists?).to be_falsey
    end

    it "accesses the modules tray for a module and cancels" do
      go_to_modules
      manage_module_button(@module).click

      # maybe should use a settings option when available
      module_index_menu_tool_link("Assign To...").click

      click_settings_tray_cancel_button

      expect(settings_tray_exists?).to be_falsey
    end

    it "accesses the modules tray and click between settings and assign to" do
      go_to_modules
      manage_module_button(@module).click

      # should use a settings option when available
      module_index_menu_tool_link("Assign To...").click

      expect(assign_to_panel).to be_displayed

      click_settings_tab
      expect(settings_panel).to be_displayed

      click_assign_to_tab
      expect(assign_to_tab).to be_displayed
    end

    it "shows 'View Assign To' when a module has an assignment override" do
      @module.assignment_overrides.create!
      go_to_modules

      expect(view_assign.text).to eq "View Assign To"
    end

    it "doesn't show 'View Assign To' when a module has no assignment overrides" do
      go_to_modules

      expect(view_assign.text).to eq ""
    end

    it "accesses the modules tray for a module via the 'View Assign To' button" do
      @module.assignment_overrides.create!
      go_to_modules

      view_assign.click

      expect(settings_tray_exists?).to be true
    end
  end

  context "uses tray to update prerequisites" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      module_setup
      @module2 = @course.context_modules.create!(name: "module2")
      @module3 = @course.context_modules.create!(name: "module3")
    end

    before do
      user_session(@teacher)
    end

    it "has no add prerequisites button when first module" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_settings_tab

      expect(add_prerequisites_button_exists?).to be_falsey
    end

    it "accesses prerequisites dropdown for module and assigns prerequisites" do
      go_to_modules
      manage_module_button(@module3).click
      module_index_menu_tool_link("Assign To...").click
      click_settings_tab

      click_add_prerequisites_button
      expect(prerequisites_dropdown[0]).to be_displayed

      select_prerequisites_dropdown_option(0, "module2")

      expect(prerequisites_dropdown_value(0)).to eq("module2")

      click_settings_tray_update_module_button

      expect(prerequisite_message(@module3).text).to eq("Prerequisites: module2")
    end

    it "adds more than one prerequisite to a module" do
      go_to_modules
      manage_module_button(@module3).click
      module_index_menu_tool_link("Assign To...").click
      click_settings_tab

      click_add_prerequisites_button

      select_prerequisites_dropdown_option(0, "module2")
      expect(prerequisites_dropdown_value(0)).to eq("module2")

      click_add_prerequisites_button

      select_prerequisites_dropdown_option(1, "module")
      expect(prerequisites_dropdown_value(1)).to eq("module")

      click_settings_tray_update_module_button

      expect(prerequisite_message(@module3).text).to eq("Prerequisites: module2, module")
    end

    it "does not save prerequisites selected when update cancelled." do
      go_to_modules
      manage_module_button(@module2).click
      module_index_menu_tool_link("Assign To...").click
      click_settings_tab

      click_add_prerequisites_button
      expect(prerequisites_dropdown[0]).to be_displayed

      select_prerequisites_dropdown_option(0, "module")

      expect(prerequisites_dropdown_value(0)).to eq("module")

      click_settings_tray_cancel_button

      expect(prerequisite_message(@module2).text).not_to eq("Prerequisites: module2")
    end
  end

  context "uses tray to update assign to settings" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      @section1 = @course.course_sections.create!(name: "section1")
      @section2 = @course.course_sections.create!(name: "section2")
      @student1 = user_factory(name: "user1", active_all: true, active_state: "active")
      @student2 = user_factory(name: "user2", active_all: true, active_state: "active", section: @section2)
      @course.enroll_user(@student1, "StudentEnrollment", enrollment_state: "active")
      @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")

      module_setup
    end

    before do
      user_session(@teacher)
    end

    it "shows the everyone radio button as checked when selecting Assign To tray" do
      go_to_modules
      manage_module_button(@module).click

      module_index_menu_tool_link("Assign To...").click

      expect(is_checked(everyone_radio_checked)).to be true
    end

    it "selects the custom radio button for module assign to when clicked" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click

      click_custom_access_radio

      expect(is_checked(custom_access_radio_checked)).to be true
    end

    it "selects the custom radio button for module assign to and cancels" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio

      expect(is_checked(custom_access_radio_checked)).to be true

      click_settings_tray_cancel_button
      expect(settings_tray_exists?).to be_falsey
    end

    it "searches for a user to assign to and selects the user" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio
      expect(assignee_selection).to be_displayed

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")
      expect(assignee_selection_item[0].text).to eq("user1")
    end

    it "adds more than one name to the assign to list" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio
      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")
      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user2")

      assignee_list = assignee_selection_item.map(&:text)
      expect(assignee_list.sort).to eq(%w[user1 user2])
    end

    it "adds a section to the list of assignees" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio

      assignee_selection.send_keys("section")
      click_option(assignee_selection, "section1")
      expect(assignee_selection_item[0].text).to eq("section1")
    end

    it "adds both user and section to assignee list" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")
      assignee_selection.send_keys("section")
      click_option(assignee_selection, "section1")

      assignee_list = assignee_selection_item.map(&:text)
      expect(assignee_list.sort).to eq(%w[section1 user1])
    end

    it "deletes added assignee by clicking on it" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")

      assignee_selection_item_remove("user1").click
      expect(element_exists?(assignee_selection_item_selector)).to be false
    end

    it "clears the assignee list when clear all is clicked" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")

      click_clear_all
      expect(element_exists?(assignee_selection_item_selector)).to be false
    end
  end
end
