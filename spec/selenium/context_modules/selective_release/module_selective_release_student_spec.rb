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

describe "selective_release modules for students" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  context "provides modules for correct students" do
    before(:once) do
      Account.site_admin.enable_feature! :differentiated_modules
      course_with_teacher(active_all: true)
      module_setup
      @module.update!(workflow_state: "active")
      @student1 = student_in_course(active_all: true, name: "Student 1").user
      @student2 = student_in_course(active_all: true, name: "Student 2").user
      @student3 = student_in_course(active_all: true, name: "Student 3").user
      @section_override1 = @module.assignment_overrides.create!(set_type: "CourseSection", set_id: @course.course_sections.first)
      @adhoc_override1 = @module.assignment_overrides.create!(set_type: "ADHOC")
      @adhoc_override1.assignment_override_students.create!(user: @student1)
    end

    it "shows module for assigned student" do
      user_session(@student1)
      go_to_modules
      expect(element_exists?(context_module_selector(@module.id))).to be_truthy
    end

    it "does not show module for un-assigned student" do
      skip("LF-689: waiting for this one to be true")
      user_session(@student2)
      go_to_modules
      expect(element_exists?(context_module_selector(@module.id))).to be_falsey
    end
  end
end
