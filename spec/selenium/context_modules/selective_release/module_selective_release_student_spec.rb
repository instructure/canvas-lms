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
require_relative "../../assignments/page_objects/assignments_index_page"

describe "selective_release modules for students" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include AssignmentsIndexPage
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common

  context "provides modules for correct students" do
    before(:once) do
      differentiated_modules_on
      course_with_teacher(active_all: true)
      @module = @course.context_modules.create!(name: "Module 1", workflow_state: "active")
      @assignment1 = @course.assignments.create!(title: "first item in module", workflow_state: "active")
      @module.add_item type: "assignment", id: @assignment1.id
      @student1 = student_in_course(active_all: true, name: "Student 1").user
      @student2 = student_in_course(active_all: true, name: "Student 2").user
      @student3 = student_in_course(active_all: true, name: "Student 3").user
      @observer1 = observer_in_course(active_all: true, name: "Observer").user
      @observer1_enrollment = @course.enroll_user(@observer1, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student1.id)
      @observer2 = observer_in_course(active_all: true, name: "Observer").user
      @observer2_enrollment = @course.enroll_user(@observer2, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student2.id)
      @adhoc_override1 = @module.assignment_overrides.create!(set_type: "ADHOC")
      @adhoc_override1.assignment_override_students.create!(user: @student1)
    end

    it "shows module for assigned student" do
      user_session(@student1)
      go_to_modules
      expect(element_exists?(context_module_selector(@module.id))).to be_truthy
    end

    it "does not show module for un-assigned student" do
      user_session(@student2)
      go_to_modules

      expect(element_exists?(context_module_selector(@module.id))).to be_falsey
      expect(element_exists?(no_context_modules_message_selector)).to be_truthy
    end

    it "does not show assignment for unassigned module" do
      user_session(@student2)
      get "/courses/#{@course.id}/assignments"

      expect(element_exists?(assignment_row_selector(@assignment1.id))).to be_falsey
    end

    it "shows module to observer of an assigned student" do
      user_session(@observer1)
      go_to_modules
      expect(element_exists?(context_module_selector(@module.id))).to be_truthy
    end

    it "does not show module to observer of an unassigned student" do
      user_session(@observer2)
      go_to_modules

      expect(element_exists?(context_module_selector(@module.id))).to be_falsey
      expect(element_exists?(no_context_modules_message_selector)).to be_truthy
    end
  end
end
