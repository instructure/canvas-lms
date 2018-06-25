#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'page_objects/assignment_page'

describe "moderated grading assignments" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:moderated_grading)
    @course = course_model
    @course.offer!
    @assignment = @course.assignments.create!(submission_types: 'online_text_entry', title: 'Test Assignment')
    @assignment.update_attribute :moderated_grading, true
    @assignment.update_attribute :grader_count, 2
    @assignment.update_attribute :workflow_state, 'published'
    @student = User.create!
    @course.enroll_student(@student)
    @user = User.create!
    @course.enroll_ta(@user)
  end

  context "with assignment moderation setting" do
    before(:each) do
      # turn on the moderation flag
      Account.default.enable_feature!(:anonymous_marking)
      Account.default.enable_feature!(:moderated_grading)
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment',
        submission_types: 'online_text_entry',
        points_possible: 10
      )

      # create a second section and enroll a second teacher
      @section2 = @course.course_sections.create!

      @teacher_two = user_factory(active_all: true)
      @course.enroll_teacher(
        @teacher_two,
        section: @section2,
        enrollment_state: 'active'
      )

      # visit assignment edit page as first teacher
      user_session(@teacher)
      AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
    end

    it "should allow user to select final moderator", priority: "1", test_id: 3482530 do
      AssignmentPage.select_moderate_checkbox
      AssignmentPage.select_grader_dropdown.click

      expect(AssignmentPage.select_grader_dropdown).to include_text(@teacher_two.name)
    end

    it "should allow user to input number of graders", priority: "1", test_id: 3490818 do
      # default value for the input is 2, or if the class has <= 2 active instructors the default is 1
      AssignmentPage.select_moderate_checkbox
      AssignmentPage.add_number_of_graders(2)
      AssignmentPage.select_grader_from_dropdown(@teacher.name)
      expect_new_page_load { AssignmentPage.assignment_save_button.click }
      expect(@moderated_assignment.reload.grader_count).to eq 2
    end
  end

  context "with moderator selected" do
    before(:each) do
      # turn on the moderation flag
      Account.default.enable_feature!(:anonymous_marking)

      # create 2 teachers
      @teacher_two = user_factory(active_all: true)
      @course.enroll_teacher(
        @teacher_two,
        enrollment_state: 'active'
      )
      @teacher_three = user_factory(active_all: true)
      @course.enroll_teacher(
        @teacher_three,
        enrollment_state: 'active'
      )

      # assign a moderator (teacher 2)
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment',
        submission_types: 'online_text_entry',
        grader_count: 2,
        final_grader: @teacher_two,
        moderated_grading: true,
        points_possible: 10
      )
    end

    context "on visiting assignment edit page as the assignment moderator" do
      before do
        user_session(@teacher_two)
        AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
      end

      it "allows assignment edits", priority: "1", test_id: 3488596 do
        expect(AssignmentPage.assignment_save_button).to be_present
      end
    end

    context "on visiting assignment edit page as non assignment moderator" do
      before do
        user_session(@teacher_three)
        AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
      end

      it "does not allow assignment edits", priority: "1", test_id: 3488597 do
        expect(AssignmentPage.assignment_edit_permission_error_text).to be_present
      end
    end

    context "on visiting assignment edit page as the account admin" do
      before do
        @account = Account.default
        account_admin_user
        user_session(@admin)
        AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
      end

      it "allows admin to edit assignment", priority: "1", test_id: 3488598 do
        expect(AssignmentPage.assignment_save_button).to be_present
      end
    end
  end
end
