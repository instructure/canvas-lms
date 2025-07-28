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

describe Loaders::AssignmentVisibilityLoader do
  before(:once) do
    # Create courses
    @course1 = course_factory(active_all: true)
    @course2 = course_factory(active_all: true)

    # Create students
    @student1 = user_factory(active_all: true)
    @student2 = user_factory(active_all: true)
    @student3 = user_factory(active_all: true)

    # Enroll students in courses
    @course1.enroll_student(@student1, enrollment_state: "active")
    @course1.enroll_student(@student2, enrollment_state: "active")
    @course2.enroll_student(@student3, enrollment_state: "active")

    # Create assignments
    @assignment1 = @course1.assignments.create!(title: "Assignment 1")
    @assignment2 = @course1.assignments.create!(title: "Assignment 2")
    @assignment3 = @course2.assignments.create!(title: "Assignment 3")
  end

  it "returns assignments with their visibility data" do
    expect(AssignmentVisibility::AssignmentVisibilityService).to receive(:users_with_visibility_by_assignment)
      .with(course_id: @course1.id, assignment_ids: [@assignment1.id, @assignment2.id])
      .and_return({
                    @assignment1.id => [@student1.id],
                    @assignment2.id => [@student1.id, @student2.id]
                  })

    expect(AssignmentVisibility::AssignmentVisibilityService).to receive(:users_with_visibility_by_assignment)
      .with(course_id: @course2.id, assignment_ids: [@assignment3.id])
      .and_return({
                    @assignment3.id => [@student3.id]
                  })

    GraphQL::Batch.batch do
      loader = Loaders::AssignmentVisibilityLoader.new

      # Test assignment 1
      loader.load(@assignment1.id).then do |result|
        expect(result).to eq [@student1.id]
      end

      # Test assignment 2
      loader.load(@assignment2.id).then do |result|
        expect(result).to eq [@student1.id, @student2.id]
      end

      # Test assignment 3
      loader.load(@assignment3.id).then do |result|
        expect(result).to eq [@student3.id]
      end
    end
  end

  it "returns an empty array for assignments with no visibility data" do
    # Create an assignment with no overrides
    @assignment4 = @course1.assignments.create!(title: "Assignment 4")

    # Mock the visibility service to return empty data for this assignment
    expect(AssignmentVisibility::AssignmentVisibilityService).to receive(:users_with_visibility_by_assignment)
      .with(course_id: @course1.id, assignment_ids: [@assignment4.id])
      .and_return({
                    @assignment4.id => []
                  })

    GraphQL::Batch.batch do
      loader = Loaders::AssignmentVisibilityLoader.new

      # Test assignment 4
      loader.load(@assignment4.id).then do |result|
        expect(result).to eq []
      end
    end
  end

  it "handles non-existent assignment IDs gracefully" do
    non_existent_id = 999_999

    GraphQL::Batch.batch do
      loader = Loaders::AssignmentVisibilityLoader.new

      # Test with a non-existent assignment ID
      loader.load(non_existent_id).then do |result|
        expect(result).to eq []
      end
    end
  end

  it "correctly handles assignments from multiple courses" do
    # We'll make separate calls for each course's assignments
    expect(AssignmentVisibility::AssignmentVisibilityService).to receive(:users_with_visibility_by_assignment)
      .with(course_id: @course1.id, assignment_ids: [@assignment1.id, @assignment2.id])
      .and_return({
                    @assignment1.id => [@student1.id],
                    @assignment2.id => [@student1.id, @student2.id]
                  })

    expect(AssignmentVisibility::AssignmentVisibilityService).to receive(:users_with_visibility_by_assignment)
      .with(course_id: @course2.id, assignment_ids: [@assignment3.id])
      .and_return({
                    @assignment3.id => [@student3.id]
                  })

    # Load all assignments in a single batch
    GraphQL::Batch.batch do
      loader = Loaders::AssignmentVisibilityLoader.new

      promises = [
        loader.load(@assignment1.id),
        loader.load(@assignment2.id),
        loader.load(@assignment3.id)
      ]

      Promise.all(promises).then do |results|
        expect(results).to eq [
          [@student1.id],
          [@student1.id, @student2.id],
          [@student3.id]
        ]
      end
    end
  end
end
