# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Loaders::OutcomeAlignmentLoader do
  before :once do
    course_model
    outcome_with_rubric
    assessment_question_bank_with_questions
    @quiz_item = assignment_quiz([], course: @course, title: "quiz item")
    @quiz_assignment = @assignment
    @assignment = @course.assignments.create!(title: "regular assignment")
    @discussion_assignment = @course.assignments.create!(title: "discussion assignment")
    @discussion_item = @course.discussion_topics.create!(
      user: @teacher,
      title: "discussion item",
      assignment: @discussion_assignment
    )
    @module1 = @course.context_modules.create!(name: "module1")
    @module2 = @course.context_modules.create!(name: "module2", workflow_state: "unpublished")
    @tag1 = @module1.add_item type: "assignment", id: @assignment.id
    @module1.add_item type: "discussion_topic", id: @discussion_item.id
    @module2.add_item type: "quiz", id: @quiz_item.id
    @rubric.associate_with(@assignment, @course, purpose: "grading")
    @rubric.associate_with(@discussion_assignment, @course, purpose: "grading")
    @rubric.associate_with(@quiz_assignment, @course, purpose: "grading")
    @outcome.align(@bank, @bank.context)

    @course.account.enable_feature!(:outcome_alignment_summary)
  end

  it "resolves to nil if context id is invalid" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        "999999", "Course"
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to nil if context type is invalid" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "InvalidContextType"
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to nil if outcome alignment summary FF is disabled" do
    @course.account.disable_feature!(:outcome_alignment_summary)

    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "Course"
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to correct number of alignments" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "Course"
      ).load(@outcome).then do |alignments|
        expect(alignments.is_a?(Array)).to be_truthy
        expect(alignments.length).to eq 5
      end
    end
  end

  it "resolves outcome alignments to assignment, rubric, quiz and discussion" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course.id, "Course"
      ).load(@outcome).then do |alignments|
        alignments.each do |alignment|
          if alignment.content_type == "Assignment"
            content_id = @assignment.id
            content_type = "Assignment"
            module_id = @module1.id
            module_name = @module1.name
            module_workflow_state = "active"
            title = @assignment.title
            if alignment.title == "discussion item"
              content_id = @discussion_assignment.id
              title = @discussion_item.title
            end
            if alignment.title == "quiz item"
              content_id = @quiz_assignment.id
              module_id = @module2.id
              module_name = @module2.name
              module_workflow_state = "unpublished"
              title = @quiz_item.title
            end
          elsif alignment.content_type == "Rubric"
            content_id = @rubric.id
            content_type = "Rubric"
            title = @rubric.title
          elsif alignment.content_type == "AssessmentQuestionBank"
            content_id = @bank.id
            content_type = "AssessmentQuestionBank"
            title = @bank.title
          end

          expect(alignment.id).not_to be_nil
          expect(alignment.content_id).to eq content_id
          expect(alignment.content_type).to eq content_type
          expect(alignment.context_id).to eq @course.id
          expect(alignment.context_type).to eq "Course"
          expect(alignment.title).to eq title
          expect(alignment.learning_outcome_id).to eq @outcome.id
          expect(alignment.module_id).to eq module_id
          expect(alignment.module_name).to eq module_name
          expect(alignment.module_workflow_state).to eq module_workflow_state
        end
      end
    end
  end

  context "when assignment with aligned outcome is first added to a module and then removed from it" do
    before do
      @tag1.destroy!
    end

    it "resolves outcome alignment to assignment with nil module id, module name and module workflow_state" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course.id, "Course"
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment.content_type == "Assignment" && alignment.title == "regular assignment"

            expect(alignment.id).not_to be_nil
            expect(alignment.content_id).to eq @assignment.id
            expect(alignment.content_type).to eq "Assignment"
            expect(alignment.context_id).to eq @course.id
            expect(alignment.context_type).to eq "Course"
            expect(alignment.title).to eq "regular assignment"
            expect(alignment.learning_outcome_id).to eq @outcome.id
            expect(alignment.module_id).to be_nil
            expect(alignment.module_name).to be_nil
            expect(alignment.module_workflow_state).to be_nil
          end
        end
      end
    end
  end
end
