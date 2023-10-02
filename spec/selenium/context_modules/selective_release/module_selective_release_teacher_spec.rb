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
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/module_selective_release_shared_examples"

describe "selective_release module set up" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  context "using tray to update settings" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      module_setup
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "selective_release module tray", :context_modules
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

    it_behaves_like "selective_release module tray prerequisites", :context_modules

    it "does not save prerequisites selected when update cancelled." do
      go_to_modules
      manage_module_button(@module2).click
      module_index_menu_tool_link("Assign To...").click
      click_settings_tab

      click_add_prerequisites_button
      expect(prerequisites_dropdown[0]).to be_displayed

      select_prerequisites_dropdown_option(0, @module.name)

      expect(prerequisites_dropdown_value(0)).to eq(@module.name)

      click_settings_tray_cancel_button

      expect(prerequisite_message(@module2).text).not_to eq("Prerequisites: module2")
    end
  end

  context "uses tray to update module requirements" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      module_setup
      @module2 = @course.context_modules.create!(name: "module2")
      @module2.add_item type: "assignment", id: @assignment2.id
      @module3 = @course.context_modules.create!(name: "module3")
    end

    before do
      user_session(@teacher)
    end

    it "selects complete all requirements shows one requirement card" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click

      click_add_requirement_button

      expect(is_checked(complete_all_radio_checked)).to be true
      expect(module_requirement_card.length).to eq(1)
    end

    it "selects complete all requirements and clicks sequential order" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      expect(require_sequential_progress(@module.id).attribute("textContent")).to eq("")
      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click
      click_add_requirement_button
      click_sequential_order_checkbox
      click_settings_tray_update_module_button

      expect(require_sequential_progress(@module.id).attribute("textContent")).to eq("true")
    end

    it "selects complete one requirement" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click
      click_add_requirement_button
      click_complete_one_radio
      expect(is_checked(complete_one_radio_checked)).to be true
      expect(module_requirement_card.length).to eq(1)
      expect(element_exists?(sequential_order_checkbox_selector, true)).to be false
    end

    it "does not show Requirements button for module with no items" do
      go_to_modules

      scroll_to_module(@module3.name)

      manage_module_button(@module3).click
      module_index_menu_tool_link("Edit").click
      expect(element_exists?(module_requirement_card_selector)).to be false
    end

    it "deletes a requirement that was created" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click

      click_add_requirement_button
      select_requirement_item_option(0, @assignment2.title)
      expect(element_value_for_attr(requirement_item[0], "title")).to eq(@assignment2.title)

      click_add_requirement_button
      select_requirement_item_option(1, @assignment3.title)
      expect(element_value_for_attr(requirement_item[1], "title")).to eq(@assignment3.title)
      expect(module_requirement_card.length).to eq(2)
      click_remove_requirement_button(1)
      expect(module_requirement_card.length).to eq(1)
    end

    it "update complete all with no sequential order for several requirements" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_settings_tab
      click_add_requirement_button
      click_sequential_order_checkbox
      select_requirement_item_option(0, @assignment2.title)
      select_requirement_type_option(0, "Mark as done")
      click_add_requirement_button
      select_requirement_item_option(1, @assignment3.title)
      select_requirement_type_option(1, "Submit the assignment")

      click_settings_tray_update_module_button
      validate_correct_pill_message(@module.id, "Complete All Items")
    end

    it "updates requirement type and shows on modules page" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click
      click_add_requirement_button
      select_requirement_item_option(0, @assignment2.title)
      select_requirement_type_option(0, "Mark as done")
      click_settings_tray_update_module_button
      assignment_tag = retrieve_assignment_content_tag(@module, @assignment2)
      expect(f("#{module_item_selector(assignment_tag.ids[0])} .requirement_type")).to have_class "must_mark_done_requirement"

      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click
      select_requirement_type_option(0, "Submit the assignment")
      click_settings_tray_update_module_button
      expect(f("#{module_item_selector(assignment_tag.ids[0])} .requirement_type")).to have_class "must_submit_requirement"
    end

    it_behaves_like "selective release module tray requirements", :context_modules
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
      @module2 = @course.context_modules.create!(name: "module2")
      @module2.add_item type: "assignment", id: @assignment2.id
      @module3 = @course.context_modules.create!(name: "module3")
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

    it_behaves_like "selective_release module tray assign to", :context_modules

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

  context "Canvas for Elementary Modules Selective Release" do
    before :once do
      Account.site_admin.enable_feature! :differentiated_modules
      teacher_setup
      module_setup(@subject_course)
      @section1 = @subject_course.course_sections.create!(name: "section1")
      @section2 = @subject_course.course_sections.create!(name: "section2")
      @student1 = student_in_course(course: @subject_course, active_all: true, name: "user1").user
      @student2 = student_in_course(coure: @subject_course, active_all: true, name: "Student 4", section: @section2).user
      @module2 = @subject_course.context_modules.create!(name: "module2")
      @module2.add_item type: "assignment", id: @assignment2.id
      @module3 = @subject_course.context_modules.create!(name: "module3")
    end

    before do
      user_session(@homeroom_teacher)
    end

    it_behaves_like "selective_release module tray", :canvas_for_elementary
    it_behaves_like "selective_release module tray prerequisites", :canvas_for_elementary
    it_behaves_like "selective_release module tray assign to", :canvas_for_elementary
    it_behaves_like "selective release module tray requirements", :canvas_for_elementary
  end
end
