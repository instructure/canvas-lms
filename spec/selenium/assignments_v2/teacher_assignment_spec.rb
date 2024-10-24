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

require_relative "page_objects/teacher_assignment_page_v2"
require_relative "../common"
require_relative "../rcs/pages/rce_next_page"

describe "as a teacher" do
  specs_require_sharding
  include RCENextPage
  include_context "in-process server selenium tests"

  context "on assignments 2 page" do
    before(:once) do
      Account.default.enable_feature!(:assignment_enhancements_teacher_view)
      @course = course_factory(name: "course", active_course: true)
      @student = student_in_course(name: "Student", course: @course, enrollment_state: :active).user
      @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    end

    context "assignment header" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry",
          workflow_state: "published",
          peer_reviews: true
        )
      end

      before do
        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows assignment title" do
        expect(TeacherViewPageV2.assignment_title(@assignment.title)).to_not be_nil
      end

      it "shows publish button" do
        expect(TeacherViewPageV2.publish_button).to be_displayed
      end

      it "shows publish status" do
        expect(TeacherViewPageV2.publish_status(@assignment.workflow_state)).to_not be_nil
      end

      it "shows edit button" do
        expect(TeacherViewPageV2.edit_button).to be_displayed
      end

      it "shows assign to button" do
        expect(TeacherViewPageV2.assign_to_button).to be_displayed
      end

      it "shows speedgrader button" do
        expect(TeacherViewPageV2.speedgrader_button).to be_displayed
      end

      it "redirects to edit assignment page when the edit button is clicked" do
        TeacherViewPageV2.edit_button.click
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
        )
      end

      it "redirects to speedgrader page when the speedgrader button is clicked" do
        first_window = driver.window_handle
        TeacherViewPageV2.speedgrader_button.click
        new_window = (driver.window_handles - [first_window]).first
        driver.switch_to.window(new_window)
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        )
        driver.close
        driver.switch_to.window(first_window)
      end

      it "shows assign to tray when assign to button is clicked" do
        TeacherViewPageV2.assign_to_button.click
        expect(TeacherViewPageV2.assign_to_tray).to be_displayed
      end

      it "shows options button" do
        expect(TeacherViewPageV2.options_button).to be_displayed
      end

      it "redirects to Peer Reviews page when the Peer Review option is clicked" do
        TeacherViewPageV2.options_button.click
        TeacherViewPageV2.peer_reviews_option.click
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
        )
      end

      it "shows send to modal when Send To option is clicked" do
        TeacherViewPageV2.options_button.click
        TeacherViewPageV2.send_to_option.click
        expect(TeacherViewPageV2.send_to_modal).to be_displayed
      end

      it "shows copy to tray when Copy To option is clicked" do
        TeacherViewPageV2.options_button.click
        TeacherViewPageV2.copy_to_option.click
        expect(TeacherViewPageV2.copy_to_tray).to be_displayed
      end
    end

    context "submitted assignments" do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_upload"
        )
        @file_attachment = attachment_model(content_type: "application/pdf", context: @student)
        @assignment.submit_homework(@student, submission_type: "online_upload", attachments: [@file_attachment])
      end

      before do
        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it "shows status pill when an assignment has recieved submissions" do
        expect(TeacherViewPageV2.status_pill).to be_displayed
      end

      it "shows download submissions modal when Download Submissions option is clicked" do
        TeacherViewPageV2.options_button.click
        TeacherViewPageV2.download_submissions_option.click
        expect(TeacherViewPageV2.download_submissions_button).to be_displayed
      end
    end
  end
end
