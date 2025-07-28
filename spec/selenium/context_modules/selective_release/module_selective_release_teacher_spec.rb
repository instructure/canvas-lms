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
      course_with_teacher(active_all: true)
      module_setup
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "selective_release module tray", :context_modules
    it_behaves_like "selective_release edit module lock until", :context_modules
    it_behaves_like "selective_release edit module lock until", :course_homepage

    it_behaves_like "selective_release add module lock until", :context_modules
    it_behaves_like "selective_release add module lock until", :course_homepage
  end

  context "uses tray to update prerequisites" do
    before(:once) do
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
      module_index_menu_tool_link("Edit").click

      expect(add_prerequisites_button_exists?).to be_falsey
    end

    it "accesses prerequisites dropdown for module and assigns prerequisites" do
      go_to_modules
      manage_module_button(@module3).click
      module_index_menu_tool_link("Edit").click

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
      module_index_menu_tool_link("Edit").click

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
      module_index_menu_tool_link("Edit").click
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
      ignore_relock

      assignment_tag = retrieve_assignment_content_tag(@module, @assignment2)
      expect(f("#{module_item_selector(assignment_tag.ids[0])} .requirement_type")).to have_class "must_mark_done_requirement"

      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click
      select_requirement_type_option(0, "Submit the assignment")
      click_settings_tray_update_module_button
      ignore_relock
      expect(f("#{module_item_selector(assignment_tag.ids[0])} .requirement_type")).to have_class "must_submit_requirement"
    end

    it "switches between requirement count radios with arrow keys" do
      go_to_modules

      scroll_to_the_top_of_modules_page
      manage_module_button(@module).click
      module_index_menu_tool_link("Edit").click
      click_add_requirement_button
      click_complete_one_radio
      expect(is_checked(complete_one_radio_checked)).to be true
      driver.action.send_keys(:arrow_up).perform
      expect(is_checked(complete_all_radio_checked)).to be true
      driver.action.send_keys(:arrow_down).perform
      expect(is_checked(complete_one_radio_checked)).to be true
    end

    it_behaves_like "selective release module tray requirements", :context_modules
  end

  context "uses tray to update assign to settings" do
    before(:once) do
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

    it "does not show the assign to buttons when the user does not have the manage_course_content_edit permission" do
      @module.assignment_overrides.create!

      go_to_modules
      manage_module_button(@module).click
      expect(f("body")).to contain_jqcss(module_index_menu_tool_link_selector("Assign To..."))
      expect(f("body")).to contain_jqcss(view_assign_to_link_selector)

      RoleOverride.create!(context: @course.account, permission: "manage_course_content_edit", role: teacher_role, enabled: false)
      go_to_modules
      manage_module_button(@module).click
      expect(f("body")).not_to contain_jqcss(module_index_menu_tool_link_selector("Assign To..."))
      expect(f("body")).not_to contain_jqcss(view_assign_to_link_selector)
    end

    it "displays correct error message if assignee list is empty" do
      go_to_modules
      manage_module_button(@module).click
      module_index_menu_tool_link("Assign To...").click
      click_custom_access_radio

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")

      click_clear_all

      error_message = f("#TextInput-messages___0")
      expect(error_message.text).to eq("A student or section must be selected")
    end

    context "differentiation tags" do
      before :once do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: true }
          a.save!
        end

        @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
        @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
        @diff_tag2 = @course.groups.create!(name: "Differentiation Tag 2", group_category: @differentiation_tag_category, non_collaborative: true)

        @diff_tag1.add_user(@student1)
        @diff_tag2.add_user(@student2)
      end

      it "can add differentiation tags as assignees to module overrides" do
        go_to_modules
        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        click_custom_access_radio

        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")
        expect(assignee_selection_item[0].text).to eq("Differentiation Tag 1")
      end

      it "differentiation tags will persist after saving" do
        go_to_modules
        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        click_custom_access_radio

        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")

        click_settings_tray_update_module_button

        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        expect(assignee_selection_item[0].text).to eq("Differentiation Tag 1")
      end

      it "differentiation tags will not show as assignee option if the account setting is disabled" do
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: false }
          a.save!
        end

        go_to_modules
        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        click_custom_access_radio

        assignee_selection.click
        options = ff("[data-testid='assignee_selector_option']").map(&:text)
        expect(options).not_to include("Differentiation")
      end

      it "displays correct error message if assignee list is empty" do
        go_to_modules
        manage_module_button(@module).click
        module_index_menu_tool_link("Assign To...").click
        click_custom_access_radio

        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")

        click_clear_all

        error_message = f("#TextInput-messages___0")
        expect(error_message.text).to eq("A student, section, or tag must be selected")
      end

      context "differentiation tag rollback" do
        it "displays error message and disables saving if differentiaiton tags exist after account setting is turned off" do
          go_to_modules

          manage_module_button(@module).click
          module_index_menu_tool_link("Assign To...").click
          click_custom_access_radio

          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 1")

          click_settings_tray_update_module_button

          # Turn off differentiaiton tags account setting
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: false }
            a.save!
          end

          # Refresh the page
          go_to_modules

          manage_module_button(@module).click
          module_index_menu_tool_link("Assign To...").click
          click_custom_access_radio

          # Check for error message on assignee selector
          error_message = f("#TextInput-messages___0")
          expect(error_message.text).to eq("Differentiation tag overrides must be removed")

          # Check for wraning box with 'convert tags' button
          expect(f("[data-testid='convert-differentiation-tags-button']")).to be_displayed
        end

        it "removes error message when user manually removes all differentiation tags from assignee selector" do
          go_to_modules

          manage_module_button(@module).click
          module_index_menu_tool_link("Assign To...").click
          click_custom_access_radio

          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 1")

          click_settings_tray_update_module_button

          # Turn off differentiaiton tags account setting
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: false }
            a.save!
          end

          # Refresh the page
          go_to_modules

          manage_module_button(@module).click
          module_index_menu_tool_link("Assign To...").click
          click_custom_access_radio

          expect(f("[data-testid='convert-differentiation-tags-button']")).to be_displayed

          # Remove differentiation tag from assignee selector
          assignee_selection_item_remove("Differentiation Tag 1").click

          # Warning message should be removed
          expect(element_exists?("[data-testid='convert-differentiation-tags-button']")).to be_falsey
        end

        it "converts differentiation tags to ADHOC overrides when 'convert tags' button is clicked" do
          go_to_modules

          manage_module_button(@module).click
          module_index_menu_tool_link("Assign To...").click
          click_custom_access_radio

          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 1")
          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 2")

          click_settings_tray_update_module_button

          # Turn off differentiaiton tags account setting
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: false }
            a.save!
          end

          # Refresh the page
          go_to_modules

          manage_module_button(@module).click
          module_index_menu_tool_link("Assign To...").click
          click_custom_access_radio

          # Click 'convert tags' button
          f("[data-testid='convert-differentiation-tags-button']").click
          wait_for_ajaximations

          # students 1 and 2 should be added to the assignee list
          expect(assignee_selection_item[0].text).to eq("user1")
          expect(assignee_selection_item[1].text).to eq("user2")
        end
      end
    end
  end

  context "uses tray to create modules" do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    before do
      user_session(@teacher)
    end

    it "brings up the add module tray when +Module clicked" do
      go_to_modules
      click_new_module_link
      expect(add_module_tray_exists?).to be true
      expect(header_label.text).to eq("Add Module")
    end

    it "adds module with a prerequisite module in same transaction" do
      first_module = @course.context_modules.create!(name: "First Module")
      go_to_modules
      click_new_module_link
      update_module_name("Second Module")
      click_add_prerequisites_button

      select_prerequisites_dropdown_option(0, first_module.name)
      expect(prerequisites_dropdown_value(0)).to eq(first_module.name)

      click_add_tray_add_module_button

      new_module = @course.context_modules.last
      expect(element_exists?(context_module_selector(new_module.id))).to be_truthy
      expect(prerequisite_message(new_module).text).to eq("Prerequisites: #{first_module.name}")
    end

    it "can cancel creation of module" do
      go_to_modules
      click_new_module_link
      update_module_name("New Module")
      click_add_tray_cancel_button
      expect(@course.context_modules.count).to eq 0
    end

    it "can close creation of module" do
      go_to_modules
      click_new_module_link
      update_module_name("New Module")
      click_add_tray_close_button
      expect(@course.context_modules.count).to eq 0
    end

    it "give error in add module tray if module name is not provided" do
      go_to_modules
      click_new_module_link
      click_add_tray_add_module_button
      expect(add_module_tray.text).to include("Module name can’t be blank")
      check_element_has_focus(module_name_input)
    end

    it_behaves_like "selective_release add module tray", :context_modules
    it_behaves_like "selective_release add module tray", :course_homepage
  end

  context "Canvas for Elementary Modules Selective Release" do
    before :once do
      teacher_setup
      module_setup(@subject_course)
      @section1 = @subject_course.course_sections.create!(name: "section1")
      @section2 = @subject_course.course_sections.create!(name: "section2")
      @student1 = student_in_course(course: @subject_course, active_all: true, name: "user1").user
      @student2 = student_in_course(course: @subject_course, active_all: true, name: "Student 4", section: @section2).user
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
    it_behaves_like "selective_release edit module lock until", :canvas_for_elementary
  end

  context "Canvas for Elementary Modules Selective Release Limited Set Up" do
    before :once do
      teacher_setup
    end

    before do
      user_session(@homeroom_teacher)
    end

    it_behaves_like "selective_release add module tray", :canvas_for_elementary
    it_behaves_like "selective_release add module lock until", :canvas_for_elementary
  end
end
