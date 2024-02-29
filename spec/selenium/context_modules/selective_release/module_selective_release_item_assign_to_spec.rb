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

require_relative "../../common"
require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/module_item_selective_release_assign_to_shared_examples"

describe "selective_release module item assign to tray" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  before(:once) do
    differentiated_modules_on
    course_with_teacher(active_all: true)

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

  context "using assign to tray for newly created items" do
    before(:once) do
      @course.context_modules.create!(name: "module1")
    end

    before do
      user_session(@teacher)
    end

    it "shows the correct icon type and title a new assignment" do
      go_to_modules
      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Assignment")).to be true
      expect(item_type_text.text).to eq("Assignment")
    end

    it "shows the correct icon type and title for a classic quiz" do
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A Classic Quiz") do
        f("label[for=classic_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end

    it "shows the correct icon type and title for an NQ quiz" do
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "An NQ Quiz") do
        f("label[for=new_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end

    it "shows the correct icon type and title for a classic quiz after indent" do
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A Classic Quiz") do
        f("label[for=classic_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_indent(module_item)
      manage_module_item_button(module_item).click
      click_manage_module_item_assign_to(module_item)

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end

    it "does not show tray when flag if off after item indent" do
      Account.site_admin.disable_feature! :differentiated_modules
      go_to_modules
      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A Classic Quiz") do
        f("label[for=classic_quizzes_radio]").click
      end
      module_item = ContentTag.last

      manage_module_item_button(module_item).click
      click_manage_module_item_indent(module_item)
      manage_module_item_button(module_item).click

      expect(element_exists?(manage_module_item_assign_to_selector(module_item.id))).to be_falsey
    end
  end

  context "assign to tray values" do
    before(:once) do
      module_setup
      @module_item1 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module_item2 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment2.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it "shows tray and Everyone pill when accessing tray for an item that has no overrides" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      expect(item_tray_exists?).to be true
      expect(module_item_assign_to_card[0]).to be_displayed
      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed
    end

    it "shows points possible only when present" do
      @assignment1.update!(points_possible: 10)
      @assignment2.update!(points_possible: nil)
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      expect(item_type_text.text).to include("10 pts")

      click_cancel_button
      manage_module_item_button(@module_item2).click
      click_manage_module_item_assign_to(@module_item2)
      expect(item_type_text.text).not_to include("pts")
    end

    it "changes pills when new card is added" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      expect(item_tray_exists?).to be true

      click_add_assign_to_card
      expect(element_exists?(assign_to_in_tray_selector("Remove Everyone"))).to be_falsey
      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    end

    it "changes first card pill to Everyone when second card deleted" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      click_add_assign_to_card
      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      click_delete_assign_to_card(1)
      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed
    end

    it "first card pill changes to Everyone else when student added to first card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      select_module_item_assignee(0, @student1.name)

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "second card selection does not contain student when student added to first card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      select_module_item_assignee(0, @student1.name)

      click_add_assign_to_card
      option_elements = INSTUI_Select_options(module_item_assignee[1])
      option_names = option_elements.map(&:text)
      expect(option_names).not_to include(@student1.name)
      expect(option_names).to include(@student2.name)
    end

    it "shows existing enrollments when accessing module item tray" do
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)

      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      expect(module_item_assign_to_card[0]).to be_displayed
      expect(module_item_assign_to_card[1]).to be_displayed

      expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "allows for item assignment for newly-created module item" do
      go_to_modules

      add_new_module_item_and_yield("#assignments_select", "Assignment", "[ Create Assignment ]", "New Assignment Title")
      latest_module_item = ContentTag.last

      manage_module_item_button(latest_module_item).click
      click_manage_module_item_assign_to(latest_module_item)

      expect(item_tray_exists?).to be true
      expect(module_item_assign_to_card[0]).to be_displayed
      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed

      select_module_item_assignee(0, @student1.name)
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "can fill out due dates and times on card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      expect(item_tray_exists?).to be true

      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")
      update_available_date(0, "12/27/2022")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/7/2023")
      update_until_time(0, "9:00 PM")

      expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
      expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
      expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
      expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
      expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
      expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
    end

    it "does not display an error when user uses other English locale" do
      @user.update! locale: "en-GB"

      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "15 April 2024")
      # Blurs the due date input
      assign_to_due_time(0).click

      expect(assign_to_date_and_time[0].text).not_to include("Invalid date")
    end

    it "does not display an error when user uses other language" do
      @user.update! locale: "es"

      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "15 de abr. de 2024")
      # Blurs the due date input
      assign_to_due_time(0).click

      expect(assign_to_date_and_time[0].text).not_to include("Fecha no válida")
    end

    it "displays an error when due date is invalid" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "wrongdate")
      # Blurs the due date input
      assign_to_due_time(0).click

      expect(assign_to_date_and_time[0].text).to include("Invalid date")
    end

    it "displays an error when the availability date is after the due date" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "12/31/2022")
      update_available_date(0, "1/1/2023")

      expect(assign_to_date_and_time[1].text).to include("Unlock date cannot be after due date")
    end

    it "can remove a student from a card with two students" do
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student2)

      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      assign_to_in_tray("Remove #{@student2.name}")[0].click
      expect(element_exists?(assign_to_in_tray_selector("Remove #{@student2.name}"))).to be_falsey
      expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
    end

    it "deletes individual cards" do
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.create!(set_type: "ADHOC")
      @module_item1.assignment.assignment_overrides.first.assignment_override_students.create!(user: @student1)
      @module_item1.assignment.assignment_overrides.second.assignment_override_students.create!(user: @student2)
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      expect(module_item_assign_to_card.count).to be(3)
      click_delete_assign_to_card(2)
      expect(module_item_assign_to_card.count).to be(2)
    end

    it "focus assignees field if there is no selection after trying to submit", :ignore_js_errors do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      assign_to_in_tray("Remove Everyone")[0].click
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")
      update_available_date(0, "12/27/2022")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/7/2023")
      update_until_time(0, "9:00 PM")
      click_save_button

      # Error: A student or section must be selected
      check_element_has_focus module_item_assignee[0]
    end

    it "focus date field if is invalid after trying to submit", :ignore_js_errors do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")
      update_available_date(0, "1/1/2023")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/2/2023")
      update_until_time(0, "9:00 PM")
      click_save_button

      # Error: Unlock date cannot be after due date
      check_element_has_focus assign_to_available_from_date(0)
    end

    it "focus date field if is un-parseable after trying to submit", :ignore_js_errors do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)
      update_due_date(0, "wrongdate")
      update_available_date(0, "1/1/2023")
      update_available_time(0, "8:00 AM")
      update_until_date(0, "1/2/2023")
      update_until_time(0, "9:00 PM")
      click_save_button

      # Error: Invalid date
      check_element_has_focus assign_to_due_date(0)
    end
  end

  context "item assign to tray saves" do
    before(:once) do
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

      module_setup
      @course.update!(default_view: "modules")
      @module_item1 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module item assign to tray", :context_modules
    it_behaves_like "module item assign to tray", :course_homepage
  end

  context "item assign to tray saves for canvas for elementary" do
    before(:once) do
      teacher_setup
      @subject_course.enable_feature! :quizzes_next
      @subject_course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @subject_course.root_account.settings[:provision] = { "lti" => "lti url" }
      @subject_course.root_account.save!

      module_setup(@subject_course)
      @module_item1 = ContentTag.find_by(context_id: @subject_course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(course: @subject_course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @subject_course, active_all: true, name: "Student 2").user
    end

    before do
      user_session(@teacher)
    end

    it_behaves_like "module item assign to tray", :canvas_for_elementary
  end
end
