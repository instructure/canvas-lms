# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../common"
require_relative "page_objects/assignment_create_edit_page"
require_relative "page_objects/assignment_page"

describe "assignment" do
  include_context "in-process server selenium tests"

  context "for submission limited attempts" do
    before(:once) do
      @course1 = Course.create!(name: "First Course1")
      @teacher1 = User.create!
      @teacher1 = User.create!(name: "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, enrollment_state: "active")
      @assignment1 = @course1.assignments.create!(
        title: "Existing Assignment",
        points_possible: 10,
        submission_types: "online_url,online_upload,online_text_entry"
      )
      @assignment2_paper = @course1.assignments.create!(
        title: "Existing Assignment",
        points_possible: 10,
        submission_types: "on_paper"
      )
    end

    before do
      user_session(@teacher1)
    end

    it "displays the attempts field on edit view" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment1.id)

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be true
    end

    it "hides attempts field for paper assignment" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment2_paper.id)

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be false
    end

    it "displays the attempts field on create view" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course1.id)
      click_option(AssignmentCreateEditPage.submission_type_selector, "External Tool")

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be true
    end

    it "hides the attempts field on create view when no submissions is needed" do
      AssignmentCreateEditPage.visit_new_assignment_create_page(@course1.id)
      click_option(AssignmentCreateEditPage.submission_type_selector, "No Submission")

      expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be false
    end

    it "allows user to set submission limit", custom_timeout: 25 do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment1.id)
      click_option(AssignmentCreateEditPage.limited_attempts_dropdown, "Limited")

      # default attempt count is 1
      expect(AssignmentCreateEditPage.limited_attempts_input.attribute("value")).to eq "1"

      # increase attempts count
      AssignmentCreateEditPage.increase_attempts_btn.click
      AssignmentCreateEditPage.assignment_save_button.click
      wait_for_ajaximations

      expect(AssignmentPage.allowed_attempts_count.text).to include "2"
    end
  end

  context "new quiz" do
    before(:once) do
      Account.site_admin.enable_feature!(:hide_zero_point_quizzes_option)
      course_with_teacher(active_all: true)
      @course.context_external_tools.create! tool_id: ContextExternalTool::QUIZ_LTI,
                                             name: "Q.N",
                                             consumer_key: "1",
                                             shared_secret: "1",
                                             domain: "quizzes.example.com",
                                             url: "http://lti13testtool.docker/launch"
      @new_quiz = @course.assignments.create!(points_possible: 0)
      @new_quiz.quiz_lti!
      @new_quiz.save!
    end

    before do
      user_session(@teacher)
    end

    it "allows user to select option to hide from gradebooks" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)

      expect(AssignmentCreateEditPage.hide_from_gradebooks_checkbox).to be_displayed
    end

    it "when the hide_from_gradebook option is selected the omit from final grade option is automatically selected and disabled" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click

      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_selected
      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_disabled
    end

    it "when the hide_from_gradebook option is deselected the omit from final grade option is automatically enabled and remains selected" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click

      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_selected
      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_enabled
    end

    it "when the points possible is edited to greater than 0 hide_from_gradebook option is hidden and the omit from final grade option is automatically enabled and remains selected" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click
      AssignmentCreateEditPage.enter_points_possible(10)
      AssignmentCreateEditPage.edit_assignment_name("test") # to get the cursor out of the points input field

      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_selected
      expect(AssignmentCreateEditPage.omit_from_final_grade_checkbox).to be_enabled
    end

    it "can be set to be hidden from gradebooks" do
      AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @new_quiz.id)
      AssignmentCreateEditPage.hide_from_gradebooks_checkbox.click
      AssignmentCreateEditPage.save_assignment

      expect(@new_quiz.reload.hide_in_gradebook).to be true
      expect(@new_quiz.reload.omit_from_final_grade).to be true
    end
  end

  context "due date" do
    before do
      course_with_teacher(active_all: true)
      user_session(@teacher)
    end

    it "fills the due date field from a selection in the popup calendar" do
      time = DateTime.new(2023, 8, 9, 12, 0, 0, 0, 0) # this is a Wednesday
      Timecop.freeze(time) do
        @assignment = @course.assignments.create!(due_at: time, points_possible: 10)

        AssignmentCreateEditPage.visit_assignment_edit_page(@course.id, @assignment.id)
        AssignmentCreateEditPage.due_date_picker_btn.click
        expect(AssignmentCreateEditPage.due_date_picker_popup).to be_displayed

        # click the next day (Thursday the 10th)
        f("td.ui-datepicker-current-day + td").click
        AssignmentCreateEditPage.due_date_picker_done_btn.click
        expect(AssignmentCreateEditPage.due_date_input.attribute("value")).to eq(
          format_time_for_datepicker(DateTime.new(2023, 8, 10, 12, 0, 0, 0, 0))
        )
      end
    end
  end
end
