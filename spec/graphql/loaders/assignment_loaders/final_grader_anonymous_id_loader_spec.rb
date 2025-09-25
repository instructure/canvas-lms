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

RSpec.describe Loaders::AssignmentLoaders::FinalGraderAnonymousIdLoader do
  before :once do
    course_with_teacher(active_all: true)
    @grader1 = @teacher
    @grader2 = teacher_in_course(course: @course, active_all: true).user
    @grader3 = teacher_in_course(course: @course, active_all: true).user
    @student = course_with_user("StudentEnrollment", course: @course, active_all: true).user

    # Create moderated assignments
    @moderated_assignment1 = @course.assignments.create!(
      title: "Moderated Assignment 1",
      moderated_grading: true,
      grader_count: 2,
      final_grader: @grader1
    )

    @moderated_assignment2 = @course.assignments.create!(
      title: "Moderated Assignment 2",
      moderated_grading: true,
      grader_count: 2,
      final_grader: @grader2
    )

    @moderated_assignment3 = @course.assignments.create!(
      title: "Moderated Assignment 3",
      moderated_grading: true,
      grader_count: 2,
      final_grader: @grader3
    )

    # Assignment without final grader
    @moderated_assignment_no_final_grader = @course.assignments.create!(
      title: "Moderated Assignment No Final Grader",
      moderated_grading: true,
      grader_count: 2
    )

    # Non-moderated assignment
    @regular_assignment = @course.assignments.create!(
      title: "Regular Assignment"
    )

    # Create moderation graders with anonymous IDs (must be exactly 5 characters)
    @moderated_assignment1.moderation_graders.create!(user: @grader1, anonymous_id: "gr1a1")
    @moderated_assignment1.moderation_graders.create!(user: @grader2, anonymous_id: "gr2a1")
    @moderated_assignment1.moderation_graders.create!(user: @grader3, anonymous_id: "gr3a1")

    @moderated_assignment2.moderation_graders.create!(user: @grader2, anonymous_id: "gr2a2")
    @moderated_assignment2.moderation_graders.create!(user: @grader1, anonymous_id: "gr1a2")
    @moderated_assignment2.moderation_graders.create!(user: @grader3, anonymous_id: "gr3a2")

    @moderated_assignment3.moderation_graders.create!(user: @grader3, anonymous_id: "gr3a3")
    @moderated_assignment3.moderation_graders.create!(user: @grader2, anonymous_id: "gr2a3")
    @moderated_assignment3.moderation_graders.create!(user: @grader1, anonymous_id: "gr1a3")

    # For assignment without final grader, still create moderation graders
    @moderated_assignment_no_final_grader.moderation_graders.create!(user: @grader2, anonymous_id: "gr2a4")
    @moderated_assignment_no_final_grader.moderation_graders.create!(user: @grader3, anonymous_id: "gr3a4")
  end

  let(:loader) { Loaders::AssignmentLoaders::FinalGraderAnonymousIdLoader.for }

  describe "#perform" do
    it "returns the correct anonymous IDs for final graders in multiple assignments" do
      assignment_ids = [
        @moderated_assignment1.id,
        @moderated_assignment2.id,
        @moderated_assignment3.id
      ]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to eq "gr1a1"
          expect(values[1]).to eq "gr2a2"
          expect(values[2]).to eq "gr3a3"
        end
      end
    end

    it "returns nil for assignments without a final grader" do
      assignment_ids = [@moderated_assignment_no_final_grader.id]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to be_nil
        end
      end
    end

    it "returns nil for non-moderated assignments" do
      assignment_ids = [@regular_assignment.id]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to be_nil
        end
      end
    end

    it "handles mixed assignment types correctly" do
      assignment_ids = [
        @moderated_assignment1.id,
        @regular_assignment.id,
        @moderated_assignment_no_final_grader.id,
        @moderated_assignment2.id
      ]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to eq "gr1a1"
          expect(values[1]).to be_nil
          expect(values[2]).to be_nil
          expect(values[3]).to eq "gr2a2"
        end
      end
    end

    it "handles empty assignment list" do
      assignment_ids = []

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values).to eq []
        end
      end
    end

    it "handles non-existent assignment IDs" do
      assignment_ids = [999_999, 888_888]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values).to all(be_nil)
        end
      end
    end

    it "returns nil when final grader is not in moderation_graders table" do
      # Create an assignment with a final grader but no corresponding moderation_grader record
      assignment_without_moderation_grader = @course.assignments.create!(
        title: "Assignment Without Moderation Grader Record",
        moderated_grading: true,
        grader_count: 2,
        final_grader: @teacher
      )
      # Create moderation graders for other users but not the final grader
      assignment_without_moderation_grader.moderation_graders.create!(user: @grader2, anonymous_id: "other")

      assignment_ids = [assignment_without_moderation_grader.id]

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values[0]).to be_nil
        end
      end
    end

    it "batches queries efficiently" do
      assignment_ids = [
        @moderated_assignment1.id,
        @moderated_assignment2.id,
        @moderated_assignment3.id
      ]

      # Ensure we're not making N+1 queries - should only make one query to ModerationGrader
      expect(ModerationGrader).to receive(:joins).once.and_call_original

      GraphQL::Batch.batch do
        promises = assignment_ids.map { |id| loader.load(id) }
        Promise.all(promises).then do |values|
          expect(values.length).to eq 3
          expect(values).to eq %w[gr1a1 gr2a2 gr3a3]
        end
      end
    end
  end
end
