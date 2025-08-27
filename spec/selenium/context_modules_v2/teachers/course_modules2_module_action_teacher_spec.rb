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
require_relative "../page_objects/modules2_action_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../helpers/assignments_common"
require_relative "../shared_examples/course_modules2_shared"
describe "context modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray
  include AssignmentsCommon
  include Modules2ActionTray

  before :once do
    modules2_teacher_setup
  end

  before do
    user_session(@teacher)
  end

  context "module action menu edit" do
    before do
      go_to_modules
      wait_for_ajaximations
    end

    it "edits a module name" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      expect(module_settings_tray).to be_displayed

      new_module_name = "Updated Module Name"
      expect(input_module_name).to be_displayed
      fill_in_module_name(new_module_name)
      click_save_module_tray_change
      expect(context_module(@module1.id).attribute("data-module-name")).to eq(new_module_name)
    end
  end

  context "uses tray to edit prerequisites" do
    it "has no add prerequisites button when first module" do
      go_to_modules
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click

      expect(element_exists?(add_prerequisite_button_selector)).to be false
    end

    it "accesses prerequisites dropdown for module and assigns prerequisites" do
      go_to_modules
      module_action_menu(@module3.id).click
      module_item_action_menu_link("Edit").click
      click_add_prerequisites_button

      expect(prerequisites_dropdown[0]).to be_displayed
      select_prerequisites_dropdown_option(0, @module2.name)
      expect(prerequisites_dropdown_value(0)).to eq(@module2.name)
      click_save_module_tray_change
      ignore_relock

      expect(context_module_prerequisites(@module3.id).text).to eq("Prerequisite: #{@module2.name}")
    end

    it "does not save prerequisites selected when update cancelled." do
      go_to_modules
      module_action_menu(@module2.id).click
      module_item_action_menu_link("Edit").click
      click_add_prerequisites_button

      expect(prerequisites_dropdown[0]).to be_displayed
      select_prerequisites_dropdown_option(0, @module1.name)
      expect(prerequisites_dropdown_value(0)).to eq(@module1.name)
      cancel_tray_button.click
      wait_for_ajaximations

      expect(element_exists?(context_module_prerequisites_selector(@module2.id))).to be false
    end

    it_behaves_like "course_module2 module tray prerequisites", :context_modules
    it_behaves_like "course_module2 module tray prerequisites", :course_homepage
  end

  context "uses tray to edit module requirements" do
    before :once do
      @module4 = @course.context_modules.create!(name: "module with no items")
      @module5 = @course.context_modules.create!(name: "module with requirements")
      @required_hw = @course.assignments.create!(title: "assignment 1")
      @required_quiz = @course.quizzes.create!(title: "quiz 1")
      @tag_1 = @module5.add_item({ id: @required_hw.id, type: "assignment" })
      @tag_2 = @module5.add_item({ id: @required_quiz.id, type: "quiz" })
      @module5.completion_requirements = { @tag_1.id => { type: "must_view" }, @tag_2.id => { type: "must_view" } }
      @module5.save!
    end

    before do
      go_to_modules
      wait_for_ajaximations
    end

    it "sets complete all as default selection and shows one requirement card" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      click_add_requirement_button
      expect(is_checked(complete_all_radio_checked)).to be true
      expect(module_requirement_card.length).to eq(1)
    end

    it "selects complete all requirements and clicks sequential order" do
      expect(element_exists?(module_header_complete_all_pill_selector(@module1.id))).to be false
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      click_add_requirement_button
      expect(sequential_order_checkbox).to be_displayed
      sequential_order_checkbox.click
      click_save_module_tray_change
      expect(context_module_completion_requirement(@module1.id).text).to include("Complete All Items")
    end

    it "selects complete one requirement" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      click_add_requirement_button
      select_complete_one_radio
      expect(is_checked(complete_one_radio_checked)).to be true
      expect(module_requirement_card.length).to eq(1)
      expect(element_exists?(sequential_order_checkbox_selector, true)).to be false
    end

    it "does not show Requirements button for module with no items" do
      module_action_menu(@module4.id).click
      module_item_action_menu_link("Edit").click
      expect(element_exists?(add_requirement_button_selector)).to be false
    end

    it "cancels a requirement session" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      click_add_requirement_button
      expect(close_tray_button).to be_displayed
      cancel_tray_button.click
      wait_for_ajaximations
      expect(element_exists?(context_module_completion_requirement_selector(@module1.id))).to be false
    end

    it "update complete all requirement to complete one" do
      module_action_menu(@module5.id).click
      module_item_action_menu_link("Edit").click
      select_complete_one_radio
      click_save_module_tray_change
      expect(context_module_completion_requirement(@module5.id).text).to include("Complete One Item")
    end

    it "updates requirement type and shows on modules page" do
      module_action_menu(@module5.id).click
      module_item_action_menu_link("Edit").click
      select_requirement_type_option(0, "Mark as done")
      select_requirement_type_option(1, "Submit the assignment")
      click_save_module_tray_change
      ignore_relock
      module_header_expand_toggles.last.click
      expect(context_module_item_todo(@module5.content_tags[0].id, "Mark as done")).to be_present
      expect(context_module_item_todo(@module5.content_tags[1].id, "Submit quiz")).to be_present
    end

    it "switches between requirement count radios with arrow keys" do
      module_action_menu(@module2.id).click
      module_item_action_menu_link("Edit").click
      click_add_requirement_button
      select_complete_one_radio
      expect(is_checked(complete_one_radio_checked)).to be true
      driver.action.send_keys(:arrow_up).perform
      expect(is_checked(complete_all_radio_checked)).to be true
      driver.action.send_keys(:arrow_down).perform
      expect(is_checked(complete_one_radio_checked)).to be true
    end

    it_behaves_like "course_module2 module tray requirements", :context_modules
    it_behaves_like "course_module2 module tray requirements", :course_homepage
  end

  context "uses tray to edit lock until" do
    it "sets lock until date to the past and not display lock until label on the module header" do
      go_to_modules
      past_date = format_date_for_view(Time.zone.today - 2.days)
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      click_lock_until_checkbox

      update_lock_until_date(past_date)
      update_lock_until_time("12:00 AM")
      click_save_module_tray_change
      expect(element_exists?(module_header_will_unlock_selector(@module1.id))).to be false
    end

    it "shows error if lock until date and time are empty on edit module tray" do
      go_to_modules
      empty_input = ""
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Edit").click
      click_lock_until_checkbox

      update_lock_until_date(empty_input)
      update_lock_until_time(empty_input)
      click_save_module_tray_change
      expect(lock_until_input.text).to include("Unlock date can’t be blank")
      check_element_has_focus(lock_until_date)
    end

    it_behaves_like "course_module2 module tray lock until", :context_modules
    it_behaves_like "course_module2 module tray lock until", :course_homepage
  end
end
