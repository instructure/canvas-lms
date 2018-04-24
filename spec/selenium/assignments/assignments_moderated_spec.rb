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
    @course = course_model
    @course.offer!
    @assignment = @course.assignments.create!(submission_types: 'online_text_entry', title: 'Test Assignment')
    @assignment.update_attribute :moderated_grading, true
    @assignment.update_attribute :workflow_state, 'published'
    @student = User.create!
    @course.enroll_student(@student)
    @user = User.create!
    @course.enroll_ta(@user)
  end

  it "publishes grades from the moderate screen" do
    sub = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'hallo')
    sub.find_or_create_provisional_grade!(@user, score: 80)

    course_with_teacher_logged_in course: @course
    get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
    f('.ModeratedGrading__Header-PublishBtn').click
    driver.switch_to.alert.accept
    assert_flash_notice_message("Success! Grades were published to the grade book")
  end

  context "student tray" do
    before(:each) do
      @account = Account.default
      @account.enable_feature!(:student_context_cards)
    end

    it "moderated assignment should display student name in tray", priority: "1", test_id: 3022071 do
      course_with_teacher_logged_in course: @course
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/moderate"
      f("a[data-student_id='#{@student.id}']").click
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
    end
  end

  context "with assignment moderation setting" do
    before(:each) do
      # turn on the moderation flag
      Account.default.enable_feature!(:anonymous_moderated_marking)
      Account.default.enable_feature!(:anonymous_marking)
      @moderated_assignment = @course.assignments.create!(title: 'Moderated Assignment',
                                                          submission_types: 'online_text_entry',
                                                          points_possible: 10)
      # create a second section and enroll a second teacher
      @second_section = @course.course_sections.create! :name => 'Second Section'
      @section2 = @course.course_sections.create!

      @teacher_two = user_factory(:active_all => true)
      @course.enroll_teacher(@teacher_two, :section => @section2,
                             :enrollment_state => 'active')
      # visit assignment edit page as first teacher
      user_session(@teacher)
      AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
    end

    it "should allow user to select final moderator", priority: "1", test_id: 3482530 do
      skip('This is skeleton code that acts as AC for GRADE-973 which is WIP')
      AssignmentPage.select_moderate_checkbox
      AssignmentPage.select_grader_dropdown.click
      expect(AssignmentPage.select_grader_dropdown).to include_text(@teacher_two.name)
    end
  end

  context "with moderator selected for an assignment" do
    before(:each) do
      # turn on the moderation flag
      Account.default.enable_feature!(:anonymous_moderated_marking)
      Account.default.enable_feature!(:anonymous_marking)

      # create 2 teachers
      @teacher_two = user_factory(active_all: true)
      @course.enroll_teacher(@teacher_two,enrollment_state: 'active')
      @teacher_three = user_factory(active_all: true)
      @course.enroll_teacher(@teacher_three, enrollment_state: 'active')

      # assign a moderator (teacher 2)
      @moderated_assignment = @course.assignments.create!(title: 'Moderated Assignment',
                                                          submission_types: 'online_text_entry',
                                                          final_grader: @teacher_two,
                                                          moderated_grading: true,
                                                          points_possible: 10)

    end

    before do
      user_session(@teacher_two)
      AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
    end

    it "should allow moderator to edit assignment", priority: "1", test_id: 3488596 do
      skip('This is skeleton code that acts as AC for GRADE-960 which is WIP')
      expect(AssignmentPage.assignment_edit_permission_error_text).not_to exist
    end

    before do
      user_session(@teacher_three)
      AssignmentPage.visit_assignment_edit_page(@course.id, @moderated_assignment.id)
    end

    it "should not allow a non moderator to edit assignment", priority: "1", test_id: 3488597 do
      skip('This is skeleton code that acts as AC for GRADE-960 which is WIP')
      expect(AssignmentPage.assignment_edit_permission_error_text).to exist
    end

    before do
      @account = Account.default
      account_admin_user
      user_session(@admin)
    end

    it "should allow admin to edit assignment", priority: "1", test_id: 3488598 do
      skip('This is skeleton code that acts as AC for GRADE-960 which is WIP')
      expect(AssignmentPage.assignment_edit_permission_error_text).not_to exist
    end
  end
end
