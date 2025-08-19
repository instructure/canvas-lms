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

RSpec.describe Loaders::AssignmentLoaders::GradedSubmissionsExistLoader do
  before :once do
    @student1 = user_with_pseudonym(username: "student@example.com", active_all: 1)
    student_in_course(user: @student1, active_all: 1)
    @student2 = user_with_pseudonym(username: "student2@example.com", active_all: 1)
    student_in_course(user: @student2, active_all: 1)

    @grader = user_with_pseudonym(name: "Grader", username: "grader@example.com", active_all: 1)

    @regular_assignment = @course.assignments.create!(
      title: "Regular Assignment",
      points_possible: 10,
      submission_types: "online_text_entry"
    )

    @moderated_assignment = @course.assignments.create!(
      title: "Moderated Assignment",
      points_possible: 10,
      submission_types: "online_text_entry",
      moderated_grading: true,
      grader_count: 2
    )

    @not_graded_assignment = @course.assignments.create!(
      title: "Not Graded Assignment",
      submission_types: "not_graded"
    )

    @wiki_page_assignment = @course.assignments.create!(
      title: "Wiki Page Assignment",
      submission_types: "wiki_page"
    )
  end

  describe "#perform" do
    it "returns false for assignments without any submissions" do
      assignment_ids = [@regular_assignment.id, @moderated_assignment.id]

      result = GraphQL::Batch.batch do
        Promise.all(assignment_ids.map do |id|
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(id)
        end)
      end

      expect(result).to all(be false)
    end

    it "returns false for assignments with ungraded submissions" do
      @regular_assignment.submit_homework(@student1, body: "submission 1")
      @regular_assignment.submit_homework(@student2, body: "submission 2")

      result = GraphQL::Batch.batch do
        Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@regular_assignment.id)
      end

      expect(result).to be false
    end

    it "returns true for assignments with graded submissions" do
      submission1 = @regular_assignment.submit_homework(@student1, body: "submission 1")
      submission1.update!(
        score: 8.5,
        workflow_state: "graded",
        graded_at: Time.current,
        grader_id: @grader.id
      )

      submission2 = @regular_assignment.submit_homework(@student2, body: "submission 2")
      submission2.update!(
        score: 9.0,
        workflow_state: "graded",
        graded_at: Time.current,
        grader_id: @grader.id
      )

      result = GraphQL::Batch.batch do
        Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@regular_assignment.id)
      end

      expect(result).to be true
    end

    it "returns true if at least one submission is graded" do
      submission1 = @regular_assignment.submit_homework(@student1, body: "submission 1")
      submission1.update!(
        score: 8.5,
        workflow_state: "graded",
        graded_at: Time.current,
        grader_id: @grader.id
      )

      @regular_assignment.submit_homework(@student2, body: "submission 2")
      # submission2 remains ungraded

      result = GraphQL::Batch.batch do
        Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@regular_assignment.id)
      end

      expect(result).to be true
    end

    it "returns false for non-gradeable assignment types (not_graded)" do
      result = GraphQL::Batch.batch do
        Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@not_graded_assignment.id)
      end

      expect(result).to be false
    end

    it "returns false for non-gradeable assignment types (wiki_page)" do
      result = GraphQL::Batch.batch do
        Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@wiki_page_assignment.id)
      end

      expect(result).to be false
    end

    context "with moderated grading" do
      before :once do
        @teacher2 = User.create!(name: "Second Teacher")
        @course.enroll_teacher(@teacher2, enrollment_state: :active)
        @moderated_assignment.moderation_graders.create!(user: @teacher, anonymous_id: "aaaaa")
        @moderated_assignment.moderation_graders.create!(user: @teacher2, anonymous_id: "bbbbb")
      end

      it "returns false for moderated assignments without provisional grades" do
        @moderated_assignment.submit_homework(@student1, body: "submission 1")
        @moderated_assignment.submit_homework(@student2, body: "submission 2")

        result = GraphQL::Batch.batch do
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@moderated_assignment.id)
        end

        expect(result).to be false
      end

      it "returns true for moderated assignments with provisional grades" do
        submission1 = @moderated_assignment.submit_homework(@student1, body: "submission 1")
        submission2 = @moderated_assignment.submit_homework(@student2, body: "submission 2")

        ModeratedGrading::ProvisionalGrade.create!(
          submission: submission1,
          scorer: @teacher,
          score: 8.5,
          grade: "8.5"
        )

        ModeratedGrading::ProvisionalGrade.create!(
          submission: submission2,
          scorer: @teacher2,
          score: 9.0,
          grade: "9.0"
        )

        result = GraphQL::Batch.batch do
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@moderated_assignment.id)
        end

        expect(result).to be true
      end

      it "returns true if at least one provisional grade exists" do
        submission1 = @moderated_assignment.submit_homework(@student1, body: "submission 1")
        @moderated_assignment.submit_homework(@student2, body: "submission 2")

        # Only create one provisional grade to test the "at least one" behavior
        ModeratedGrading::ProvisionalGrade.create!(
          submission: submission1,
          scorer: @teacher,
          score: 8.5,
          grade: "8.5"
        )

        result = GraphQL::Batch.batch do
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@moderated_assignment.id)
        end

        expect(result).to be true
      end

      it "ignores provisional grades with nil scores" do
        submission1 = @moderated_assignment.submit_homework(@student1, body: "submission 1")

        ModeratedGrading::ProvisionalGrade.create!(
          submission: submission1,
          scorer: @teacher,
          score: nil,
          grade: nil
        )

        result = GraphQL::Batch.batch do
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@moderated_assignment.id)
        end

        expect(result).to be false
      end

      it "ignores provisional grades for submissions with nil submission_type" do
        submission1 = @moderated_assignment.submit_homework(@student1, submission_type: nil)

        ModeratedGrading::ProvisionalGrade.create!(
          submission: submission1,
          scorer: @teacher,
          score: 8.5,
          grade: "8.5"
        )

        result = GraphQL::Batch.batch do
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(@moderated_assignment.id)
        end

        expect(result).to be false
      end
    end

    it "can handle multiple assignments in a batch" do
      submission1 = @regular_assignment.submit_homework(@student1, body: "submission 1")
      submission1.update!(
        score: 8.5,
        workflow_state: "graded",
        graded_at: Time.current,
        grader_id: @grader.id
      )

      @moderated_assignment.submit_homework(@student2, body: "submission 2")

      assignment_ids = [@regular_assignment.id, @moderated_assignment.id, @not_graded_assignment.id]

      results = GraphQL::Batch.batch do
        Promise.all(assignment_ids.map do |id|
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(id)
        end)
      end

      expect(results[0]).to be true  # regular_assignment has graded submission
      expect(results[1]).to be false # moderated_assignment has no graded submissions
      expect(results[2]).to be false # not_graded_assignment is not gradeable
    end

    it "returns false for non-existent assignment IDs" do
      non_existent_id = Assignment.maximum(:id).to_i + 1000

      result = GraphQL::Batch.batch do
        Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(non_existent_id)
      end

      expect(result).to be false
    end

    it "handles mixed batch with existing and non-existing assignment IDs" do
      non_existent_id = Assignment.maximum(:id).to_i + 1000

      submission = @regular_assignment.submit_homework(@student1, body: "submission 1")
      submission.update!(
        score: 8.5,
        workflow_state: "graded",
        graded_at: Time.current,
        grader_id: @grader.id
      )

      assignment_ids = [@regular_assignment.id, non_existent_id, @moderated_assignment.id]

      results = GraphQL::Batch.batch do
        Promise.all(assignment_ids.map do |id|
          Loaders::AssignmentLoaders::GradedSubmissionsExistLoader.load(id)
        end)
      end

      expect(results[0]).to be true  # regular_assignment has graded submission
      expect(results[1]).to be false # non-existent assignment
      expect(results[2]).to be false # moderated_assignment has no graded submissions
    end
  end
end
