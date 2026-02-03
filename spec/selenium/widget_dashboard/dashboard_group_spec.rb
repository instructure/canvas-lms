# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "page_objects/widget_dashboard_page"
require_relative "../helpers/student_dashboard_common"

describe "student dashboard group specific tests", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    group_assignment_course_setup
    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student3, @student_no_group, @student1_group1, @student2_group1)

    @group_assignment = @course4.assignments.create!(
      name: "Group Project",
      due_at: 2.days.from_now.end_of_day,
      submission_types: "online_text_entry",
      group_category: @group_category,
      grade_group_students_individually: false,
      points_possible: 10,
      only_visible_to_overrides: true
    )
    create_group_override_for_assignment(@group_assignment, group: @group1)
  end

  context "group assignments visibility tests" do
    it "only shows group assignment to students in the assigned group" do
      user_session(@student3)
      go_to_dashboard
      expect(element_exists?(course_work_item_selector(@group_assignment.id))).to be_falsey
    end

    it "does not show group assignment to student not in any group" do
      user_session(@student_no_group)
      go_to_dashboard
      expect(element_exists?(course_work_item_selector(@group_assignment.id))).to be_falsey
    end
  end

  context "group assignment submission status" do
    before :once do
      group_assignment_setup
    end

    it "shows both grading types in course work widget" do
      user_session(@student1_group1)
      go_to_dashboard

      expect(course_work_item(@group_assignment.id)).to be_displayed
      expect(course_work_item(@group_assignment_graded_individually.id)).to be_displayed
      expect(all_course_work_items.size).to eq(2)
    end

    it "shows submitted status for all group members when one submits" do
      submit_group_assignment

      user_session(@student1_group1)
      go_to_dashboard
      filter_course_work_by(:date, "Submitted")
      expect(course_work_item(@group_assignment.id)).to be_displayed
      expect(course_work_item(@group_assignment_graded_individually.id)).to be_displayed
      expect(all_course_work_items.size).to eq(2)

      # Student 2 should also see it as submitted
      destroy_session
      user_session(@student2_group1)
      go_to_dashboard
      filter_course_work_by(:date, "Submitted")
      expect(course_work_item(@group_assignment.id)).to be_displayed
      expect(course_work_item(@group_assignment_graded_individually.id)).to be_displayed
      expect(all_course_work_items.size).to eq(2)
    end

    it "shows missing status for all group members when no one submits" do
      user_session(@student1_group1)
      go_to_dashboard
      filter_course_work_by(:date, "Missing")
      expect(course_work_item(@missing_group_assignment.id)).to be_displayed
      expect(course_work_item(@missing_graded_individually.id)).to be_displayed

      destroy_session
      user_session(@student2_group1)
      go_to_dashboard
      filter_course_work_by(:date, "Missing")
      expect(course_work_item(@missing_group_assignment.id)).to be_displayed
      expect(course_work_item(@missing_graded_individually.id)).to be_displayed
    end
  end

  context "multiple group assignments" do
    before :once do
      # Create multiple group categories and assignments
      @group_category2 = @course4.group_categories.create!(name: "Lab Groups")
      @lab_group = @course4.groups.create!(name: "Lab Group A", group_category: @group_category2)
      @lab_group.add_user(@student1_group1)

      @lab_assignment = @course4.assignments.create!(
        name: "Lab Group Assignment",
        due_at: 3.days.from_now.end_of_day,
        submission_types: "online_text_entry",
        group_category: @group_category2,
        grade_group_students_individually: false,
        points_possible: 10,
        only_visible_to_overrides: true
      )
      create_group_override_for_assignment(@lab_assignment, group: @lab_group)
    end

    it "displays assignments from all groups student belongs to" do
      user_session(@student1_group1)
      go_to_dashboard

      expect(course_work_item(@group_assignment.id)).to be_displayed
      expect(course_work_item(@lab_assignment.id)).to be_displayed
      expect(all_course_work_items.size).to eq(2)
    end

    it "only shows assignments from student's groups" do
      # Student 2 is only in group1, not in lab group
      user_session(@student2_group1)
      go_to_dashboard

      expect(course_work_item(@group_assignment.id)).to be_displayed
      expect(element_exists?(course_work_item_selector(@lab_assignment.id))).to be_falsey
      expect(all_course_work_items.size).to eq(1)
    end
  end

  context "as observer" do
    before :once do
      @observer = user_factory(active_all: true, name: "Observer")
      enable_widget_dashboard_for(@observer)
      @course4.enroll_user(@observer,
                           "ObserverEnrollment",
                           associated_user_id:
                           @student1_group1.id,
                           enrollment_state: :active)
    end

    it "displays group assignments for observed student" do
      user_session(@observer)
      go_to_dashboard

      expect(course_work_item(@group_assignment.id)).to be_displayed
    end

    it "shows group submission status for observed student" do
      @group_assignment.submit_homework(@student1_group1,
                                        submission_type:
                                        "online_text_entry",
                                        body: "Group submission")

      user_session(@observer)
      go_to_dashboard
      filter_course_work_by(:date, "Submitted")
      expect(course_work_item(@group_assignment.id)).to be_displayed
    end
  end
end
