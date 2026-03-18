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
      assignment.due_at = 1.minute.from_now
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
      assignment.due_at = 1.minute.from_now
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
      assignment.due_at = Time.zone.now + 60
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

    it "displays discussion checkpoints in to do list for a student", priority: "1" do
      @course.account.enable_feature!(:discussion_checkpoints)
      reply_to_topic, reply_to_entry = graded_discussion_topic_with_checkpoints(context: @course)

      get "/"
      wait_for_ajaximations
      f("#DashboardOptionsMenu_Container button").click
      fj('span[role="menuitemradio"]:contains("Recent Activity")').click
      # verify that both discussion checkpoints are in the to do list
      list_items = ff("#planner-todosidebar-item-list>li")
      expect(list_items.first).to include_text(reply_to_topic.title.to_s + " Reply to Topic")
      expect(list_items.second).to include_text(reply_to_entry.title.to_s + " Required Replies (3)")
    end

    context "peer review sub assignments" do
      it "displays peer review sub assignments in to do list for a student", priority: "1" do
        parent_assignment = assignment_model(
          course: @course,
          name: "Assignment 101",
          peer_reviews: true,
          peer_review_count: 1,
          due_at: 2.days.from_now
        )
        peer_review_model(
          parent_assignment:,
          due_at: 5.days.from_now
        )

        get "/"
        wait_for_ajaximations

        list_items = ff("#planner-todosidebar-item-list>li")
        peer_review_item = list_items.find { |item| item.text.include?("Assignment 101 Peer Review (1)") }

        expect(peer_review_item).not_to be_nil
        expect(peer_review_item).to include_text("Assignment 101 Peer Review (1)")
      end

      it "displays correct due date for student-specific override in to do list", priority: "1" do
        override_due_date = 5.days.from_now
        parent_assignment = assignment_model(
          course: @course,
          name: "Assignment 202",
          peer_reviews: true,
          peer_review_count: 1,
          due_at: 2.days.from_now
        )
        peer_review_sub = peer_review_model(
          parent_assignment:,
          due_at: 4.days.from_now
        )

        parent_override = parent_assignment.assignment_overrides.create!(set_type: "ADHOC")
        parent_override.assignment_override_students.create!(user: @student)

        child_override = peer_review_sub.assignment_overrides.create!(
          set_type: "ADHOC",
          parent_override_id: parent_override.id,
          due_at: override_due_date,
          due_at_overridden: true
        )
        child_override.assignment_override_students.create!(user: @student)

        get "/"
        wait_for_ajaximations

        list_items = ff("#planner-todosidebar-item-list>li")
        peer_review_item = list_items.find { |item| item.text.include?("Assignment 202 Peer Review (1)") }

        expect(peer_review_item).not_to be_nil
        expect(peer_review_item).to include_text("Assignment 202 Peer Review (1)")

        expected_date_text = format_date_for_view(override_due_date, "%b %-d")
        expect(peer_review_item.text).to include(expected_date_text)
      end

      it "displays correct due date for section override in to do list", priority: "2" do
        section1 = @course.course_sections.create!(name: "Section 1")
        section2 = @course.course_sections.create!(name: "Section 2")
        student2 = user_factory(active_all: true, name: "Student 2")
        @course.enroll_student(student2, enrollment_state: "active", section: section2)
        @student.enrollments.first.update!(course_section: section1)
        base_due_date = 5.days.from_now
        section_override_date = 6.days.from_now
        parent_assignment = assignment_model(
          course: @course,
          name: "Assignment 303",
          peer_reviews: true,
          peer_review_count: 1,
          due_at: 2.days.from_now
        )
        peer_review_sub = peer_review_model(
          parent_assignment:,
          due_at: base_due_date
        )

        parent_override = parent_assignment.assignment_overrides.create!(set: section1)
        peer_review_sub.assignment_overrides.create!(
          set: section1,
          parent_override_id: parent_override.id,
          due_at: section_override_date,
          due_at_overridden: true
        )

        get "/"
        wait_for_ajaximations

        list_items = ff("#planner-todosidebar-item-list>li")
        peer_review_item = list_items.find { |item| item.text.include?("Assignment 303 Peer Review (1)") }

        expect(peer_review_item).not_to be_nil
        expect(peer_review_item).to include_text("Assignment 303 Peer Review (1)")
        expected_section_date = format_date_for_view(section_override_date, "%b %-d")
        expect(peer_review_item.text).to include(expected_section_date)

        user_session(student2)
        get "/"
        wait_for_ajaximations

        list_items = ff("#planner-todosidebar-item-list>li")
        peer_review_item = list_items.find { |item| item.text.include?("Assignment 303 Peer Review (1)") }

        expect(peer_review_item).not_to be_nil
        expect(peer_review_item).to include_text("Assignment 303 Peer Review (1)")
        expected_base_date = format_date_for_view(base_due_date, "%b %-d")
        expect(peer_review_item.text).to include(expected_base_date)
      end

      it "displays correct due date for group override in to do list", priority: "2" do
        @course.enable_feature!(:peer_review_allocation_and_grading)
        group_category = @course.group_categories.create!(name: "Project Groups")
        group1 = @course.groups.create!(name: "Group 1", group_category:)
        student2 = user_factory(active_all: true, name: "Student 2")
        @course.enroll_student(student2, enrollment_state: "active")
        group1.add_user(@student)
        base_due_date = 5.days.from_now
        group_override_date = 7.days.from_now
        parent_assignment = @course.assignments.create!(
          name: "Assignment 404",
          peer_reviews: true,
          peer_review_count: 1,
          due_at: 2.days.from_now,
          group_category:
        )
        peer_review_sub = PeerReview::PeerReviewCreatorService.call(
          parent_assignment:,
          due_at: base_due_date,
          points_possible: 10
        )
        peer_review_sub.reload

        parent_override = parent_assignment.assignment_overrides.create!(set: group1)
        peer_review_sub.assignment_overrides.create!(
          set: group1,
          parent_override:,
          due_at: group_override_date,
          due_at_overridden: true
        )

        get "/"
        wait_for_ajaximations

        list_items = ff("#planner-todosidebar-item-list>li")
        peer_review_item = list_items.find { |item| item.text.include?("Assignment 404 Peer Review (1)") }

        expect(peer_review_item).not_to be_nil
        expect(peer_review_item).to include_text("Assignment 404 Peer Review (1)")
        expected_group_date = format_date_for_view(group_override_date, "%b %-d")
        expect(peer_review_item.text).to include(expected_group_date)

        user_session(student2)
        get "/"
        wait_for_ajaximations

        list_items = ff("#planner-todosidebar-item-list>li")
        peer_review_item = list_items.find { |item| item.text.include?("Assignment 404 Peer Review (1)") }

        expect(peer_review_item).not_to be_nil
        expect(peer_review_item).to include_text("Assignment 404 Peer Review (1)")
        expected_base_date = format_date_for_view(base_due_date, "%b %-d")
        expect(peer_review_item.text).to include(expected_base_date)
      end
    end
  end
end
