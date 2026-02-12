# frozen_string_literal: true

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
require_relative "../common"
require_relative "../../spec_helper"
require_relative "page_objects/assignments_index_page"

describe "assignments index peer review sub-assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsIndexPage

  before(:once) do
    @course = course_factory(name: "course", active_course: true)
    @course.enable_feature!(:peer_review_allocation_and_grading)

    @teacher = teacher_in_course(name: "teacher", course: @course, enrollment_state: :active).user
    @student1 = student_in_course(name: "Student 1", course: @course, enrollment_state: :active).user
    @student2 = student_in_course(name: "Student 2", course: @course, enrollment_state: :active).user
  end

  before do
    user_session(@student1)
  end

  context "Show By Date categorization" do
    before(:once) do
      @now = Time.zone.now
    end

    it "displays undated peer review sub-assignments in the Undated category" do
      assignment = @course.assignments.create!(
        name: "Undated Peer Review Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(due_at: nil, lock_at: nil, unlock_at: nil)

      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      undated_group = f("#assignment_group_undated")
      expect(undated_group).to include_text("#{assignment.name} Peer Reviews")
    end

    it "displays upcoming peer review sub-assignments in the Upcoming category" do
      assignment = @course.assignments.create!(
        name: "Upcoming Peer Review Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(
        due_at: @now + 2.days,
        lock_at: @now + 5.days,
        unlock_at: @now - 1.day
      )

      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      upcoming_group = f("#assignment_group_upcoming")
      expect(upcoming_group).to include_text("#{assignment.name} Peer Reviews")
    end

    it "displays overdue peer review sub-assignments in the Overdue category" do
      assignment = @course.assignments.create!(
        name: "Overdue Peer Review Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(
        due_at: @now - 2.days,
        lock_at: @now + 2.days,
        unlock_at: @now - 5.days
      )

      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      overdue_group = f("#assignment_group_overdue")
      expect(overdue_group).to include_text("#{assignment.name} Peer Reviews")
    end

    it "displays closed peer review sub-assignments in the Past category" do
      assignment = @course.assignments.create!(
        name: "Past Peer Review Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(
        due_at: @now - 5.days,
        lock_at: @now - 2.days,
        unlock_at: @now - 10.days
      )

      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      past_group = f("#assignment_group_past")
      expect(past_group).to include_text("#{assignment.name} Peer Reviews")
    end
  end

  context "with assignment overrides" do
    before(:once) do
      @now = Time.zone.now
      @section1 = @course.course_sections.create!(name: "Section 1")
      @section2 = @course.course_sections.create!(name: "Section 2")

      @student1.enrollments.first.update!(course_section: @section1)
      @student2.enrollments.first.update!(course_section: @section2)
    end

    it "categorizes peer review sub-assignment based on student's section override" do
      assignment = @course.assignments.create!(
        name: "Override Peer Review Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry",
        due_at: @now + 5.days
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(
        due_at: @now + 5.days,
        lock_at: @now + 10.days
      )

      parent_override = assignment.assignment_overrides.create!(
        set: @section1
      )
      child_override = peer_review_sub.assignment_overrides.create!(
        set: @section1,
        parent_override_id: parent_override.id
      )
      child_override.override_due_at(@now - 2.days)
      child_override.override_lock_at(@now + 2.days)
      child_override.save!

      user_session(@student1)
      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      overdue_group = f("#assignment_group_overdue")
      expect(overdue_group).to include_text("#{assignment.name} Peer Reviews")

      user_session(@student2)
      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      upcoming_group = f("#assignment_group_upcoming")
      expect(upcoming_group).to include_text("#{assignment.name} Peer Reviews")
    end

    it "categorizes as past when student's override lock_at has passed" do
      assignment = @course.assignments.create!(
        name: "Closed Override Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(
        due_at: @now + 5.days,
        lock_at: @now + 10.days
      )

      parent_override = assignment.assignment_overrides.create!(
        set: @section1
      )
      child_override = peer_review_sub.assignment_overrides.create!(
        set: @section1,
        parent_override_id: parent_override.id
      )
      child_override.override_due_at(@now - 5.days)
      child_override.override_lock_at(@now - 1.day)
      child_override.save!

      user_session(@student1)
      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      past_group = f("#assignment_group_past")
      expect(past_group).to include_text("#{assignment.name} Peer Reviews")
    end

    it "categorizes as undated when student's override has no due date" do
      assignment = @course.assignments.create!(
        name: "No Due Date Override Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry",
        due_at: @now + 5.days
      )

      peer_review_sub = assignment.create_peer_review_sub_assignment!
      peer_review_sub.update!(due_at: @now + 5.days)

      parent_override = assignment.assignment_overrides.create!(
        set: @section1
      )
      child_override = peer_review_sub.assignment_overrides.create!(
        set: @section1,
        parent_override_id: parent_override.id
      )
      child_override.override_due_at(nil)
      child_override.override_lock_at(@now + 10.days)
      child_override.override_unlock_at(@now - 1.day)
      child_override.save!

      user_session(@student1)
      visit_assignments_index_page(@course.id)

      f("label[for='show_by_date']").click
      wait_for_ajaximations

      undated_group = f("#assignment_group_undated")
      expect(undated_group).to include_text("#{assignment.name} Peer Reviews")
    end
  end

  context "Show By Type" do
    it "displays peer review sub-assignments under their parent assignment group" do
      assignment_group = @course.assignment_groups.create!(name: "Homework", context: @course)
      assignment = @course.assignments.create!(
        assignment_group:,
        name: "Grouped Assignment",
        peer_reviews: true,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      assignment.create_peer_review_sub_assignment!

      visit_assignments_index_page(@course.id)

      peer_review_element = wait_for(method: nil, timeout: 5) do
        fj("li:contains('#{assignment.name} Peer Reviews')")
      end

      expect(peer_review_element).to be_displayed

      assignments_list = f("#ag-list")
      expect(assignments_list).to include_text("#{assignment.name} Peer Reviews")
    end
  end
end
