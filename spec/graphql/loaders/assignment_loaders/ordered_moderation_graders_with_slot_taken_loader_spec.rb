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

describe Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader do
  before :once do
    course_with_teacher(active_all: true)
    @teacher1 = @teacher
    @teacher2 = User.create!(name: "Another Teacher")
    @course.enroll_teacher(@teacher2, enrollment_state: :active)
    @teacher3 = User.create!(name: "Third Teacher")
    @course.enroll_teacher(@teacher3, enrollment_state: :active)

    # Create an assignment with moderation enabled
    @assignment = @course.assignments.create!(
      title: "Moderated Assignment",
      moderated_grading: true,
      grader_count: 3
    )

    # Create another assignment for multi-assignment testing
    @assignment2 = @course.assignments.create!(
      title: "Another Moderated Assignment",
      moderated_grading: true,
      grader_count: 3
    )
  end

  it "returns an empty array for an assignment with no moderation graders" do
    # Execute the loader
    result = GraphQL::Batch.batch do
      Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment.id)
    end

    expect(result).to eq([])
  end

  it "returns only moderation graders with slot_taken true" do
    # Create moderation graders with different slot_taken values
    @assignment.moderation_graders.create!(user: @teacher1, anonymous_id: "anon1", slot_taken: true)
    @assignment.moderation_graders.create!(user: @teacher2, anonymous_id: "anon2", slot_taken: false)
    @assignment.moderation_graders.create!(user: @teacher3, anonymous_id: "anon3", slot_taken: true)

    # Execute the loader
    result = GraphQL::Batch.batch do
      Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment.id)
    end

    expect(result.length).to eq(2)
    expect(result.map(&:user_id)).to contain_exactly(@teacher1.id, @teacher3.id)
    expect(result.map(&:slot_taken).all?).to be true
  end

  it "orders moderation graders by anonymous_id" do
    # Create moderation graders with different anonymous_ids
    @assignment.moderation_graders.create!(user: @teacher1, anonymous_id: "ccccc", slot_taken: true)
    @assignment.moderation_graders.create!(user: @teacher2, anonymous_id: "aaaaa", slot_taken: true)
    @assignment.moderation_graders.create!(user: @teacher3, anonymous_id: "bbbbb", slot_taken: true)

    # Execute the loader
    result = GraphQL::Batch.batch do
      Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment.id)
    end

    expect(result.length).to eq(3)
    expect(result.map(&:anonymous_id)).to eq(%w[aaaaa bbbbb ccccc])
  end

  it "can handle multiple assignments in a batch" do
    # Create moderation graders for both assignments
    @assignment.moderation_graders.create!(user: @teacher1, anonymous_id: "anon1", slot_taken: true)
    @assignment.moderation_graders.create!(user: @teacher2, anonymous_id: "anon2", slot_taken: true)
    @assignment2.moderation_graders.create!(user: @teacher3, anonymous_id: "anon3", slot_taken: true)

    # Execute the loader for multiple assignments
    results = GraphQL::Batch.batch do
      Promise.all([
                    Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment.id),
                    Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment2.id)
                  ])
    end

    expect(results[0].length).to eq(2)
    expect(results[0].map(&:user_id)).to contain_exactly(@teacher1.id, @teacher2.id)

    expect(results[1].length).to eq(1)
    expect(results[1].first.user_id).to eq(@teacher3.id)
  end

  it "returns an empty array for a non-existent assignment ID" do
    non_existent_id = Assignment.maximum(:id).to_i + 1000

    # Execute the loader with a non-existent assignment id
    result = GraphQL::Batch.batch do
      Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(non_existent_id)
    end

    expect(result).to eq([])
  end

  it "correctly handles when some assignments have no moderation graders" do
    # Create moderation graders only for the first assignment
    @assignment.moderation_graders.create!(user: @teacher1, anonymous_id: "anon1", slot_taken: true)
    @assignment.moderation_graders.create!(user: @teacher2, anonymous_id: "anon2", slot_taken: true)

    # Execute the loader for multiple assignments
    results = GraphQL::Batch.batch do
      Promise.all([
                    Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment.id),
                    Loaders::AssignmentLoaders::OrderedModerationGradersWithSlotTakenLoader.load(@assignment2.id)
                  ])
    end

    expect(results[0].length).to eq(2)
    expect(results[0].map(&:user_id)).to contain_exactly(@teacher1.id, @teacher2.id)

    expect(results[1]).to eq([])
  end
end
