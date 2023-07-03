# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "page_objects/student_assignment_page_v2"
require_relative "../common"
require_relative "../helpers/assignments_common"

describe "assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  context "as a student" do
    context "past locked" do
      before(:once) do
        Account.default.enable_feature!(:assignments_2_student)
        course_with_student(course: @course, active_all: true)
        @assignment = @course.assignments.create!(
          name: "locked_assignment",
          due_at: 5.days.ago,
          unlock_at: 10.days.ago,
          lock_at: 3.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
      end

      it "shows locked image" do
        expect(StudentAssignmentPageV2.assignment_locked_image).to be_displayed
      end

      it "shows details toggle" do
        expect(StudentAssignmentPageV2.details_toggle).to be_displayed
      end
    end

    context "future locked" do
      before(:once) do
        Account.default.enable_feature!(:assignments_2_student)
        course_with_student(course: @course, active_all: true)
        @assignment = @course.assignments.create!(
          name: "locked_assignment",
          due_at: 5.days.from_now,
          unlock_at: 3.days.from_now,
          lock_at: 10.days.from_now,
          points_possible: 10,
          submission_types: "online_text_entry"
        )
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
      end

      it "shows future locked image" do
        expect(StudentAssignmentPageV2.assignment_future_locked_image).to be_displayed
      end

      it "does not show details container" do
        expect(f("#content")).to_not include_text("Details")
      end
    end

    context "prerequisite locked" do
      before(:once) do
        Account.default.enable_feature!(:assignments_2_student)
        course_with_student(course: @course, active_all: true)
        module1 = @course.context_modules.create!(name: "First Module")
        module2 = @course.context_modules.create!(name: "Second Module")
        assignment1 = @course.assignments.create!(
          name: "prereq_assignment",
          points_possible: 10,
          submission_types: "online_text_entry"
        )
        @assignment2 = @course.assignments.create!(
          name: "locked_assignment",
          points_possible: 10,
          submission_types: "online_text_entry"
        )
        tag = module1.add_item(type: "assignment", id: assignment1.id)
        module2.add_item(type: "assignment", id: @assignment2.id)
        module1.update!(completion_requirements: [{ id: tag.id, type: "must_submit" }])
        module2.update!(prerequisites: [{ id: module1.id, name: module1.name, type: "context_module" }])
      end

      before do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment2)
      end

      it "shows prerequisite locked image" do
        expect(StudentAssignmentPageV2.assignment_prerequisite_locked_image).to be_displayed
      end

      it "does not show details container" do
        expect(f("#content")).to_not include_text("Details")
      end

      it "links to modules page" do
        expect(StudentAssignmentPageV2.modules_link).to be_displayed
      end
    end
  end
end
