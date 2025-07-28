# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "page_objects/teacher_assignment_edit_page_v2"
require_relative "../common"
require_relative "../rcs/pages/rce_next_page"

describe "as a teacher" do
  specs_require_sharding
  include RCENextPage
  include_context "in-process server selenium tests"

  context "on assignments 2 create/edit page" do
    before(:once) do
      Account.default.enable_feature!(:assignment_edit_enhancements_teacher_view)
      @course = course_factory(name: "course", active_course: true)
      @student = student_in_course(name: "Student", course: @course, enrollment_state: :active).user
      @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    end

    context "assignment edit page" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment 1",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry",
          workflow_state: "published",
          peer_reviews: true
        )
      end

      before do
        user_session(@teacher)
        TeacherCreateEditPageV2.visit_edit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows edit assignment" do
        expect(TeacherCreateEditPageV2.assignment_title("Edit Assignment")).to_not be_nil
      end

      it "shows publish status" do
        expect(TeacherCreateEditPageV2.publish_status(@assignment.workflow_state)).to_not be_nil
      end

      it "shows options button" do
        expect(TeacherCreateEditPageV2.options_button).to be_displayed
      end

      it "redirects to speedgrader page when the speedgrader button is clicked" do
        first_window = driver.window_handle
        TeacherCreateEditPageV2.options_button.click
        TeacherCreateEditPageV2.speedgrader_option.click
        new_window = (driver.window_handles - [first_window]).first
        driver.switch_to.window(new_window)
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        )
        driver.close
        driver.switch_to.window(first_window)
      end

      it "redirects to assignments index page when the delete assignment option is clicked" do
        TeacherCreateEditPageV2.options_button.click
        TeacherCreateEditPageV2.delete_assignment_option.click
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/assignments"
        )
      end
    end

    context "assignment create page" do
      before do
        user_session(@teacher)
        TeacherCreateEditPageV2.visit_create(@course)
        wait_for_ajaximations
      end

      it "shows create assignment" do
        expect(TeacherCreateEditPageV2.assignment_title("Create Assignment")).to_not be_nil
      end

      it "shows unpublished status" do
        expect(TeacherCreateEditPageV2.publish_status("Unpublished")).to_not be_nil
      end

      it "shows options button" do
        expect(TeacherCreateEditPageV2.options_button).to be_displayed
      end

      it "redirects to assignments index when the delete assignment option is clicked" do
        TeacherCreateEditPageV2.options_button.click
        TeacherCreateEditPageV2.delete_assignment_option.click
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/assignments"
        )
      end
    end
  end
end
