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
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/module_selective_release_shared_examples"

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
    Account.site_admin.enable_feature! :differentiated_modules
    course_with_teacher(active_all: true)
  end

  context "using assign to tray for newly created items" do
    before(:once) do
      @course.context_modules.create!(name: "module1")

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
  end

  context "assign to tray values" do
    before(:once) do
      module_setup
      @module_item1 = ContentTag.find_by(context_id: @course.id, context_module_id: @module.id, content_type: "Assignment", content_id: @assignment1.id)
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

    it "first card pill stays Everyone when student added to first card" do
      go_to_modules

      manage_module_item_button(@module_item1).click
      click_manage_module_item_assign_to(@module_item1)

      select_module_item_assignee(0, @student1.name)

      expect(assign_to_in_tray("Remove Everyone")[0]).to be_displayed
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
      expect(assign_to_date_and_time[0].text).to include("Saturday, December 31, 2022 5:00 PM")
      expect(assign_to_date_and_time[1].text).to include("Tuesday, December 27, 2022 8:00 AM")
      expect(assign_to_date_and_time[2].text).to include("Saturday, January 7, 2023 9:00 PM")
    end
  end
end
