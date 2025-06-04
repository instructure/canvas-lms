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
#

require_relative "../graphql_spec_helper"

describe Types::ModuleStatisticsType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end

  let_once(:module1) do
    @module = course.context_modules.create!(name: "Module 1")
  end

  let_once(:assignment1) do
    assignment = course.assignments.create!(title: "Assignment 1", workflow_state: "published", submission_types: ["online_text_entry"])
    module1.add_item(type: "assignment", id: assignment.id)
    assignment
  end

  let_once(:assignment2) do
    assignment = course.assignments.create!(title: "Assignment 2", workflow_state: "published", submission_types: ["online_text_entry"])
    module1.add_item(type: "assignment", id: assignment.id)
    assignment
  end

  let_once(:assignment3) do
    assignment = course.assignments.create!(title: "Assignment 3", workflow_state: "published", submission_types: ["online_text_entry"])
    module1.add_item(type: "assignment", id: assignment.id)
    assignment
  end

  let_once(:module_type) { GraphQLTypeTester.new(module1, current_user: @student) }

  describe "module submissionStatistics" do
    let(:now) { Time.zone.now }

    describe "latestDueAt" do
      it "returns the latest due date among all assignments in the module" do
        Timecop.freeze(now) do
          submission1 = assignment1.submissions.find_by(user_id: @student.id)
          submission1.update!(cached_due_date: now + 2.days)

          submission2 = assignment2.submissions.find_by(user_id: @student.id)
          submission2.update!(cached_due_date: now + 1.day)

          result = module_type.resolve("submissionStatistics { latestDueAt }")

          expect(Time.zone.parse(result)).to be_within(1.second).of(now + 2.days)
        end
      end

      it "returns nil when no assignments have due dates" do
        result = module_type.resolve("submissionStatistics { latestDueAt }")
        expect(result).to be_nil
      end
    end

    describe "missingAssignmentCount" do
      it "returns the count of overdue assignments" do
        Timecop.freeze(now) do
          submission = assignment1.submissions.find_by(user_id: @student.id)
          submission.update!(cached_due_date: now - 1.day, late_policy_status: nil, grader_id: nil)

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 1
        end
      end

      it "includes assignments marked as missing in the overdue count" do
        Timecop.freeze(now) do
          submission = assignment1.submissions.find_by(user_id: @student.id)
          submission.update!(cached_due_date: now - 1.day, late_policy_status: "missing")

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 1
        end
      end

      it "returns zero when no assignments are overdue" do
        Timecop.freeze(now) do
          submission = assignment1.submissions.find_by(user_id: @student.id)
          submission.update!(cached_due_date: now + 1.day)

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")

          expect(result).to eq 0
        end
      end

      it "excludes unpublished assignments from the overdue count" do
        Timecop.freeze(now) do
          # Setup: One published and one unpublished assignment, both overdue
          assignment1.update!(workflow_state: "unpublished")
          submission1 = assignment1.submissions.find_by(user_id: @student.id)
          submission1.update!(cached_due_date: now - 1.day, late_policy_status: "missing")

          assignment2.update!(workflow_state: "published")
          submission2 = assignment2.submissions.find_by(user_id: @student.id)
          submission2.update!(cached_due_date: now - 1.day, late_policy_status: "missing")

          expect(assignment1.published?).to be false
          expect(assignment2.published?).to be true
          expect(submission1.missing?).to be true
          expect(submission2.missing?).to be true

          result = module_type.resolve("submissionStatistics { missingAssignmentCount }")
          expect(result).to eq 1
        end
      end
    end
  end

  describe "edge cases" do
    it "returns zero overdue count when the module has no content tags" do
      empty_module = course.context_modules.create!(name: "Empty Module")
      module_type = GraphQLTypeTester.new(empty_module, current_user: @student)

      result = module_type.resolve("submissionStatistics { missingAssignmentCount }")
      expect(result).to eq 0
    end

    it "returns zero overdue count when no submissions are overdue" do
      new_student = user_factory(active_all: true)
      course.enroll_student(new_student, enrollment_state: "active")

      sub = assignment1.submissions.find_by(user_id: new_student.id)
      expect(sub).not_to be_nil
      expect(sub.cached_due_date).to be_nil
      expect(sub.missing?).to be false

      module_type = GraphQLTypeTester.new(module1, current_user: new_student)

      result = module_type.resolve("submissionStatistics { missingAssignmentCount }")
      expect(result).to eq 0
    end

    it "returns nil for latest_due_at when the module has no content tags" do
      empty_module = course.context_modules.create!(name: "Empty Module")
      module_type = GraphQLTypeTester.new(empty_module, current_user: @student)

      result = module_type.resolve("submissionStatistics { latestDueAt }")
      expect(result).to be_nil
    end

    it "returns nil for latest_due_at when no submissions have due dates" do
      assignment1.submissions.find_by(user_id: @student.id).update!(cached_due_date: nil)
      assignment2.submissions.find_by(user_id: @student.id).update!(cached_due_date: nil)
      assignment3.submissions.find_by(user_id: @student.id).update!(cached_due_date: nil)

      result = module_type.resolve("submissionStatistics { latestDueAt }")
      expect(result).to be_nil
    end
  end
end
