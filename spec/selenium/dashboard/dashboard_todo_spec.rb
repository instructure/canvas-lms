# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe "dashboard" do
  include_context "in-process server selenium tests"

  context "as a student" do
    before do
      course_with_student_logged_in(active_all: true)
    end

    it "limits the number of visible items in the to do list", priority: "1" do
      due_date = Time.now.utc + 2.days
      20.times do
        assignment_model due_at: due_date, course: @course, submission_types: "online_text_entry"
      end

      get "/"
      wait_for_ajaximations
      expect(ff("#planner-todosidebar-item-list>li")).to have_size(7)
      fj(".Sidebar__TodoListContainer button:contains('Show All')").click
      wait_for_ajaximations
      expect(ff("#dashboard-planner-header button")).to have_size(4)
    end

    it "displays assignments to do in to do list for a student", priority: "1" do
      notification_model(name: "Assignment Due Date Changed")
      notification_policy_model(notification_id: @notification.id)
      assignment = assignment_model({ submission_types: "online_text_entry", course: @course })
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      get "/"

      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      # verify assignment changed notice is in messages
      f(".stream-assignment .stream_header").click
      expect(f("#assignment-details")).to include_text("Assignment Due Date Changed")
      # verify assignment is in to do list
      expect(f("#planner-todosidebar-item-list>li")).to include_text(assignment.title)
    end

    it "does not display assignments for soft-concluded courses in to do list for a student", priority: "1" do
      notification_model(name: "Assignment Due Date Changed")
      notification_policy_model(notification_id: @notification.id)
      assignment = assignment_model({ submission_types: "online_text_entry", course: @course })
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      @course.start_at = 1.month.ago
      @course.conclude_at = 2.weeks.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      get "/"

      expect(f("#content")).not_to contain_css(".to-do-list")
    end

    it "allows to do list items to be hidden", priority: "1" do
      notification_model(name: "Assignment Due Date Changed")
      notification_policy_model(notification_id: @notification.id)
      assignment = assignment_model({ submission_types: "online_text_entry", course: @course })
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      get "/"
      wait_for_ajaximations
      expect(f("#planner-todosidebar-item-list>li")).to include_text(assignment.title)
      f(".ToDoSidebarItem__Close button").click
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css("#planner-todosidebar-item-list>li")

      get "/"

      expect(f("#content")).not_to contain_css("#planner-todosidebar-item-list")
    end
  end
end
