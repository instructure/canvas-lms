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

  context "using assign to tray for newly created items" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
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
      click_manage_module_item_assign_to

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
      click_manage_module_item_assign_to

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
      click_manage_module_item_assign_to

      expect(item_tray_exists?).to be true
      expect(icon_type_exists?("Quiz")).to be true
      expect(item_type_text.text).to eq("Quiz")
    end
  end
end
