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
      @course = course_factory(name: "course", active_course: true)
      @course.enable_feature!(:assignment_enhancements_teacher_view)
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

    context "assignment description" do
      context "without peer review tabs" do
        before(:once) do
          @assignment = @course.assignments.create!(
            name: "assignment with description",
            description: "<p>This is a detailed assignment description</p>",
            due_at: 5.days.from_now,
            points_possible: 10,
            submission_types: "online_text_entry"
          )
        end

        before do
          user_session(@teacher)
          TeacherViewPageV2.visit(@course, @assignment)
          wait_for_ajaximations
        end

        it "displays assignment description when peer reviews are disabled" do
          expect(TeacherViewPageV2.assignment_description).to be_displayed
          expect(TeacherViewPageV2.assignment_description.text).to include("This is a detailed assignment description")
        end

        it "does not show assignment tabs when peer reviews are disabled" do
          expect(element_exists?("[data-testid='assignment-tab']")).to be_falsey
          expect(element_exists?("[data-testid='peer-review-tab']")).to be_falsey
        end
      end

      context "with peer review tabs" do
        before(:once) do
          @course.enable_feature!(:peer_review_allocation_and_grading)
          @assignment = @course.assignments.create!(
            name: "assignment with peer reviews",
            description: "<p>Description within tabs</p>",
            due_at: 5.days.from_now,
            points_possible: 10,
            submission_types: "online_text_entry",
            peer_reviews: true
          )
        end

        before do
          user_session(@teacher)
          TeacherViewPageV2.visit(@course, @assignment)
          wait_for_ajaximations
        end

        it "displays assignment and peer review tabs" do
          expect(TeacherViewPageV2.assignment_tab).to be_displayed
          expect(TeacherViewPageV2.peer_review_tab).to be_displayed
        end

        it "displays description in the assignment tab" do
          expect(TeacherViewPageV2.assignment_description).to be_displayed
          expect(TeacherViewPageV2.assignment_description.text).to include("Description within tabs")
        end
      end

      context "with empty description" do
        before(:once) do
          @assignment = @course.assignments.create!(
            name: "assignment without description",
            description: "",
            due_at: 5.days.from_now,
            points_possible: 10,
            submission_types: "online_text_entry"
          )
        end

        before do
          user_session(@teacher)
          TeacherViewPageV2.visit(@course, @assignment)
          wait_for_ajaximations
        end

        it "displays fallback message when description is empty" do
          expect(TeacherViewPageV2.assignment_description).to be_displayed
          expect(TeacherViewPageV2.assignment_description.text).to include("No additional details were added for this assignment.")
        end
      end
    end

    context "assignment footer" do
      before do
        # Create 3 assignments and put them in a module together
        @assignments = Array.new(3) do |i|
          @course.assignments.create!(
            name: "assignment_#{i + 1}",
            due_at: 5.days.from_now,
            points_possible: 10,
            submission_types: "online_upload"
          )
        end

        @content_tags = []

        @module = @course.context_modules.create!(name: "Module 1")
        @assignments.each do |assignment|
          tag = @module.add_item({ type: "assignment", id: assignment.id })
          @content_tags << tag
        end
      end

      it "renders 'Previous' and 'Next' buttons when viewing the middle assignment" do
        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignments[1])
        wait_for_ajaximations

        expect(TeacherViewPageV2.previous_assignment_button).to be_displayed
        expect(TeacherViewPageV2.next_assignment_button).to be_displayed
      end

      it "navigates to the previous assignment when 'Previous' button is clicked" do
        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignments[1])
        wait_for_ajaximations

        TeacherViewPageV2.previous_assignment_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.assignment_title(@assignments[0].title)).to be_displayed

        # only the 'Next' button should be visible on the first assignment
        expect(TeacherViewPageV2.next_assignment_button).to be_displayed
        expect(element_exists?("[data-testid='previous-assignment-button']")).to be_falsey
      end

      it "navigates to the next assignment when 'Next' button is clicked" do
        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignments[1])
        wait_for_ajaximations

        TeacherViewPageV2.next_assignment_button.click
        wait_for_ajaximations

        expect(TeacherViewPageV2.assignment_title(@assignments[2].title)).to be_displayed

        # only the 'Previous' button should be visible on the last assignment
        expect(TeacherViewPageV2.previous_assignment_button).to be_displayed
        expect(element_exists?("[data-testid='next-assignment-button']")).to be_falsey
      end

      it "does not render 'Previous' and 'Next' buttons when only one assignment exists in one module" do
        # Remove two of the assignments from the module
        @content_tags[0].destroy
        @content_tags[2].destroy
        @module.reload

        user_session(@teacher)
        TeacherViewPageV2.visit(@course, @assignments[1])
        wait_for_ajaximations

        expect(element_exists?("[data-testid='previous-assignment-button']")).to be_falsey
        expect(element_exists?("[data-testid='next-assignment-button']")).to be_falsey
      end
    end
  end
end
