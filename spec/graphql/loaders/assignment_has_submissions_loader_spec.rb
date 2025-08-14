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

require "spec_helper"

RSpec.describe Loaders::AssignmentHasSubmissionsLoader do
  before :once do
    course_with_teacher(active_all: true)
    @assignment1 = @course.assignments.create!(title: "Assignment 1", points_possible: 10)
    @assignment2 = @course.assignments.create!(title: "Assignment 2", points_possible: 10)
    @assignment3 = @course.assignments.create!(title: "Assignment 3", points_possible: 10)

    @student1 = course_with_user("StudentEnrollment", course: @course, active_all: true).user
    @student2 = course_with_user("StudentEnrollment", course: @course, active_all: true).user
  end

  let(:loader) { Loaders::AssignmentHasSubmissionsLoader.for }

  describe "#perform" do
    it "returns false for assignments without submissions" do
      assignment_ids = [@assignment1.id, @assignment2.id, @assignment3.id]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values).to all(be false)
        end
      end
    end

    it "returns true for assignments with submissions" do
      # Create submissions for assignment1 and assignment2
      @assignment1.submit_homework(@student1, body: "submission 1")
      @assignment2.submit_homework(@student2, body: "submission 2")

      assignment_ids = [@assignment1.id, @assignment2.id, @assignment3.id]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to be true  # assignment1 has submission
          expect(values[1]).to be true  # assignment2 has submission
          expect(values[2]).to be false # assignment3 has no submission
        end
      end
    end

    it "ignores deleted submissions" do
      submission = @assignment1.submit_homework(@student1, body: "submission")
      submission.update!(workflow_state: "deleted")

      GraphQL::Batch.batch do
        loader.load(@assignment1.id).then do |result|
          expect(result).to be false
        end
      end
    end

    it "ignores submissions without content" do
      # Find the existing submission and update it to have no submission_type
      submission = @assignment1.submissions.find_by(user: @student1)
      submission.update!(submission_type: nil)

      GraphQL::Batch.batch do
        loader.load(@assignment1.id).then do |result|
          expect(result).to be false
        end
      end
    end

    it "prevents N+1 queries when checking multiple assignments" do
      assignment_ids = [@assignment1.id, @assignment2.id, @assignment3.id]
      @assignment1.submit_homework(@student1, body: "submission")

      expect do
        GraphQL::Batch.batch do
          promises = assignment_ids.map { |id| loader.load(id) }
          Promise.all(promises).then(&:itself)
        end
      end.to make_database_queries(count: 1, matching: /SELECT.*assignment_id.*FROM.*submissions/)
    end

    it "handles empty assignment array" do
      expect do
        GraphQL::Batch.batch do
          # No assignments to load
        end
      end.not_to raise_error
    end

    it "works with assignments from different courses" do
      other_course = course_factory(active_all: true)
      other_assignment = other_course.assignments.create!(title: "Other Assignment", points_possible: 5)
      other_student = course_with_user("StudentEnrollment", course: other_course, active_all: true).user

      # Add submission to our assignment
      @assignment1.submit_homework(@student1, body: "submission")
      # Add submission to other course assignment
      other_assignment.submit_homework(other_student, body: "other submission")

      GraphQL::Batch.batch do
        promises = [
          loader.load(@assignment1.id),
          loader.load(@assignment2.id),
          loader.load(other_assignment.id)
        ]

        Promise.all(promises).then do |values|
          expect(values[0]).to be true   # has submission
          expect(values[1]).to be false  # no submission
          expect(values[2]).to be true   # has submission
        end
      end
    end
  end
end
