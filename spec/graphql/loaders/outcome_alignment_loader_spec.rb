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

require_relative "../../outcome_alignments_spec_helper"

describe Loaders::OutcomeAlignmentLoader do
  before :once do
    course_model
    outcome_with_rubric
    assessment_question_bank_with_questions
    @quiz1 = assignment_quiz([], course: @course, title: "quiz")
    @quiz1_assignment = @assignment
    @discussion_assignment = @course.assignments.create!(title: "discussion assignment")
    @discussion_item = @course.discussion_topics.create!(
      user: @teacher,
      title: "discussion item",
      assignment: @discussion_assignment
    )
    # quiz aligned with outcome via question bank
    @outcome.align(@bank, @bank.context)
    @quiz2 = assignment_quiz([], course: @course, title: "quiz with questions from questions bank")
    @quiz2_assignment = @assignment
    @quiz2.add_assessment_questions [@q1, @q2]
    @assignment = @course.assignments.create!(title: "regular assignment")
    @module1 = @course.context_modules.create!(name: "module1")
    @module2 = @course.context_modules.create!(name: "module2", workflow_state: "unpublished")
    @tag1 = @module1.add_item type: "assignment", id: @assignment.id
    @module1.add_item type: "discussion_topic", id: @discussion_item.id
    @module1.add_item type: "quiz", id: @quiz2.id
    @module2.add_item type: "quiz", id: @quiz1.id
    @rubric.associate_with(@assignment, @course, purpose: "grading")
    @rubric.associate_with(@discussion_assignment, @course, purpose: "grading")
    @rubric.associate_with(@quiz1_assignment, @course, purpose: "grading")

    @course.account.enable_feature!(:improved_outcomes_management)
  end

  def base_url
    ["/courses", @course.id].join("/")
  end

  def url(alignment)
    return [base_url, "rubrics", alignment[:content_id]].join("/") if alignment[:content_type] == "Rubric"
    return [base_url, "question_banks", alignment[:content_id]].join("/") if alignment[:content_type] == "AssessmentQuestionBank"
    return [base_url, "assignments", alignment[:content_id]].join("/") if alignment[:content_type] == "Assignment"

    base_url
  end

  def module_url(alignment)
    [base_url, "modules", alignment[:module_id]].join("/") if alignment[:module_id]
  end

  def new_quiz_alignment_id(quiz_id, quiz_items = nil, module_id = nil)
    alignment_id = quiz_id
    if quiz_items.present?
      item_ids_hash = quiz_items.pluck(:_id).join("_").hash
      alignment_id = [alignment_id, "IH", item_ids_hash].join("_")
    end
    base_id = ["E", alignment_id].join("_")

    return [base_id, module_id].join("_") if module_id

    base_id
  end

  it "resolves to nil if context is invalid" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        nil
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to nil if improved outcomes management FF is disabled" do
    @course.account.disable_feature!(:improved_outcomes_management)

    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course
      ).load(@outcome).then do |alignment|
        expect(alignment).to be_nil
      end
    end
  end

  it "resolves to correct number of alignments" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course
      ).load(@outcome).then do |alignments|
        expect(alignments.is_a?(Array)).to be_truthy
        expect(alignments.length).to eq 6
      end
    end
  end

  it "resolves outcome alignments to assignment, rubric, quiz, discussion and quiz with question bank" do
    GraphQL::Batch.batch do
      Loaders::OutcomeAlignmentLoader.for(
        @course
      ).load(@outcome).then do |alignments|
        alignments.each do |alignment|
          if alignment[:content_type] == "Assignment"
            content_id = @assignment.id
            content_type = "Assignment"
            module_id = @module1.id
            module_name = @module1.name
            module_url = [base_url, "modules", alignment[:module_id]].join("/") if alignment[:module_id]
            module_workflow_state = "active"
            title = @assignment.title
            assignment_content_type = "assignment"
            assignment_workflow_state = "published"
            if alignment[:title] == @discussion_item.title
              content_id = @discussion_assignment.id
              title = @discussion_item.title
              assignment_content_type = "discussion"
            end
            if alignment[:title] == @quiz1.title
              content_id = @quiz1_assignment.id
              module_id = @module2.id
              module_name = @module2.name
              module_workflow_state = "unpublished"
              title = @quiz1.title
              assignment_content_type = "quiz"
            end
            if alignment[:title] == @quiz2.title
              content_id = @quiz2_assignment.id
              title = @quiz2.title
              assignment_content_type = "quiz"
            end
          elsif alignment[:content_type] == "Rubric"
            content_id = @rubric.id
            content_type = "Rubric"
            title = @rubric.title
          elsif alignment[:content_type] == "AssessmentQuestionBank"
            content_id = @bank.id
            content_type = "AssessmentQuestionBank"
            title = @bank.title
          end

          expect(alignment[:_id]).not_to be_nil
          expect(alignment[:content_id]).to eq content_id
          expect(alignment[:content_type]).to eq content_type
          expect(alignment[:context_id]).to eq @course.id
          expect(alignment[:context_type]).to eq "Course"
          expect(alignment[:title]).to eq title
          expect(alignment[:url]).to eq url(alignment)
          expect(alignment[:learning_outcome_id]).to eq @outcome.id
          expect(alignment[:module_id]).to eq module_id
          expect(alignment[:module_name]).to eq module_name
          expect(alignment[:module_url]).to eq module_url
          expect(alignment[:module_workflow_state]).to eq module_workflow_state
          expect(alignment[:assignment_content_type]).to eq assignment_content_type
          expect(alignment[:assignment_workflow_state]).to eq assignment_workflow_state
          expect(alignment[:quiz_items]).to be_nil
          expect(alignment[:alignments_count]).to eq 1
        end
      end
    end
  end

  context "when Outcome Alignment Summary with New Quizzes FF is enabled" do
    before do
      @course.enable_feature!(:outcome_alignment_summary_with_new_quizzes)
      @new_quiz = @course.assignments.create!(title: "new quiz - aligned in OS", submission_types: "external_tool")
      @module1.add_item type: "assignment", id: @new_quiz.id
      allow_any_instance_of(OutcomesServiceAlignmentsHelper)
        .to receive(:get_os_aligned_outcomes)
        .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id))
    end

    it "resolves outcome alignments to new quiz in Outcomes-Service" do
      count = 0
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:assignment_content_type] == "new_quiz"

            count += 1
            module_url = [base_url, "modules", alignment[:module_id]].join("/") if alignment[:module_id]

            expect(alignment[:_id]).not_to be_nil
            expect(alignment[:content_id]).to eq @new_quiz.id
            expect(alignment[:content_type]).to eq "Assignment"
            expect(alignment[:context_id]).to eq @course.id
            expect(alignment[:context_type]).to eq "Course"
            expect(alignment[:title]).to eq @new_quiz.title
            expect(alignment[:url]).to eq url(alignment)
            expect(alignment[:learning_outcome_id]).to eq @outcome.id
            expect(alignment[:module_id]).to eq @module1.id
            expect(alignment[:module_name]).to eq @module1.name
            expect(alignment[:module_url]).to eq module_url
            expect(alignment[:module_workflow_state]).to eq "active"
            expect(alignment[:assignment_content_type]).to eq "new_quiz"
            expect(alignment[:assignment_workflow_state]).to eq "published"
            expect(alignment[:quiz_items]).to eq []
            expect(alignment[:alignments_count]).to eq 1
          end
        end
      end
      expect(count).to eq 1
    end

    it "resolves outcome alignments to new quiz in both Canvas (via rubric) and Outcomes-Service" do
      @rubric.associate_with(@new_quiz, @course, purpose: "grading")
      count = 0
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            count += 1 if alignment[:assignment_content_type] == "new_quiz"
          end
        end
      end
      expect(count).to eq 2
    end

    it "resolves outcome alignments to both new quiz and to quiz questions in Outcomes-Service" do
      allow_any_instance_of(OutcomesServiceAlignmentsHelper)
        .to receive(:get_os_aligned_outcomes)
        .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id, with_items: true))
      count = 0
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:assignment_content_type] == "new_quiz"

            count += 1
            module_url = [base_url, "modules", alignment[:module_id]].join("/") if alignment[:module_id]

            quiz_items = OutcomeAlignmentsSpecHelper
                         .mock_os_aligned_outcomes([@outcome], @new_quiz.id, with_items: true)[@outcome.id.to_s]
                         .filter { |a| a[:artifact_type] == "quizzes.item" }
                         .map { |a| { _id: a[:artifact_id], title: a[:title] } }

            expect(alignment[:_id]).to eq new_quiz_alignment_id(@new_quiz.id, quiz_items, alignment[:module_id])
            expect(alignment[:content_id]).to eq @new_quiz.id
            expect(alignment[:content_type]).to eq "Assignment"
            expect(alignment[:context_id]).to eq @course.id
            expect(alignment[:context_type]).to eq "Course"
            expect(alignment[:title]).to eq @new_quiz.title
            expect(alignment[:url]).to eq url(alignment)
            expect(alignment[:learning_outcome_id]).to eq @outcome.id
            expect(alignment[:module_id]).to eq @module1.id
            expect(alignment[:module_name]).to eq @module1.name
            expect(alignment[:module_url]).to eq module_url
            expect(alignment[:module_workflow_state]).to eq "active"
            expect(alignment[:assignment_content_type]).to eq "new_quiz"
            expect(alignment[:assignment_workflow_state]).to eq "published"
            expect(alignment[:quiz_items]).to match_array([{ _id: "101", title: "Question Number 101" }, { _id: "102", title: "Question Number 102" }])
            expect(alignment[:alignments_count]).to eq 3
          end
        end
      end
      expect(count).to eq 1
    end

    it "resolves outcome alignments to quiz questions in Outcomes-Service" do
      allow_any_instance_of(OutcomesServiceAlignmentsHelper)
        .to receive(:get_os_aligned_outcomes)
        .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id, with_quiz: false, with_items: true))
      count = 0
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:assignment_content_type] == "new_quiz"

            count += 1
            module_url = [base_url, "modules", alignment[:module_id]].join("/") if alignment[:module_id]

            expect(alignment[:_id]).not_to be_nil
            expect(alignment[:content_id]).to eq @new_quiz.id
            expect(alignment[:content_type]).to eq "Assignment"
            expect(alignment[:context_id]).to eq @course.id
            expect(alignment[:context_type]).to eq "Course"
            expect(alignment[:title]).to eq @new_quiz.title
            expect(alignment[:url]).to eq url(alignment)
            expect(alignment[:learning_outcome_id]).to eq @outcome.id
            expect(alignment[:module_id]).to eq @module1.id
            expect(alignment[:module_name]).to eq @module1.name
            expect(alignment[:module_url]).to eq module_url
            expect(alignment[:module_workflow_state]).to eq "active"
            expect(alignment[:assignment_content_type]).to eq "new_quiz"
            expect(alignment[:assignment_workflow_state]).to eq "published"
            expect(alignment[:quiz_items]).to match_array([{ _id: "101", title: "Question Number 101" }, { _id: "102", title: "Question Number 102" }])
            expect(alignment[:alignments_count]).to eq 2
          end
        end
      end
      expect(count).to eq 1
    end
  end

  context "when assignment with aligned outcome is first added to a module and then removed from it" do
    before do
      @tag1.destroy!
    end

    it "resolves outcome alignment to assignment with null values for module id, module name and module workflow_state" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:content_type] == "Assignment" && alignment[:title] == @assignment.title

            expect(alignment[:_id]).not_to be_nil
            expect(alignment[:content_id]).to eq @assignment.id
            expect(alignment[:content_type]).to eq "Assignment"
            expect(alignment[:context_id]).to eq @course.id
            expect(alignment[:context_type]).to eq "Course"
            expect(alignment[:title]).to eq @assignment.title
            expect(alignment[:url]).to eq url(alignment)
            expect(alignment[:learning_outcome_id]).to eq @outcome.id
            expect(alignment[:module_id]).to be_nil
            expect(alignment[:module_name]).to be_nil
            expect(alignment[:module_url]).to be_nil
            expect(alignment[:module_workflow_state]).to be_nil
            expect(alignment[:assignment_content_type]).to eq "assignment"
          end
        end
      end
    end
  end

  context "when outcome is aligned to the same quiz via rubric and question bank" do
    before do
      @rubric.associate_with(@quiz2_assignment, @course, purpose: "grading")
    end

    it "displays only once the outcome alignment to the quiz" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          expect(alignments.is_a?(Array)).to be_truthy
          expect(alignments.length).to eq 6
        end
      end
    end
  end

  context "when aligned assignment, graded discussion or quiz are unpublished" do
    before do
      @assignment.unpublish
      @discussion_assignment.unpublish
      @quiz1_assignment.unpublish
      @quiz2_assignment.unpublish
    end

    it "resolves module name properly" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:content_type] == "Assignment"

            module_id = @module1.id
            module_name = @module1.name
            module_url = [base_url, "modules", alignment[:module_id]].join("/") if alignment[:module_id]
            module_workflow_state = "active"

            if alignment[:title] == @quiz1.title
              module_id = @module2.id
              module_name = @module2.name
              module_workflow_state = "unpublished"
            end

            expect(alignment[:module_id]).to eq module_id
            expect(alignment[:module_name]).to eq module_name
            expect(alignment[:module_url]).to eq module_url
            expect(alignment[:module_workflow_state]).to eq module_workflow_state
          end
        end
      end
    end

    it "resolves assignment workflow state to 'unpublished'" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:content_type] == "Assignment"

            expect(alignment[:assignment_workflow_state]).to eq "unpublished"
          end
        end
      end
    end
  end

  context "when outcome is aligned to a question bank and the question bank title is updated" do
    before do
      @bank.title = "Updated question bank title"
      @bank.save!
    end

    it "resolves the question bank alignment title to the updated question bank title" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:content_type] == "AssessmentQuestionBank"

            expect(alignment[:title]).to eq "Updated question bank title"
          end
        end
      end
    end
  end

  context "when outcome is aligned to a rubric and the rubric title is updated" do
    before do
      @rubric.title = "Updated rubric title"
      @rubric.save!
    end

    it "resolves the rubric alignment title to the updated rubric title" do
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          alignments.each do |alignment|
            next unless alignment[:content_type] == "Rubric"

            expect(alignment[:title]).to eq "Updated rubric title"
          end
        end
      end
    end
  end

  context "when outcome is aligned to a question bank and a question from the bank has a workflow state of" do
    it "active, the outcome alignments includes the alignment to the quiz" do
      @bank = AssessmentQuestionBank.find(@bank.id)
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          expect(alignments.pluck(:title).include?(@quiz2.title)).to be true
        end
      end
    end

    it "independently_edited, the outcome alignments includes the alignment to the quiz" do
      @bank.assessment_questions.each do |q|
        q.workflow_state = "independently_edited"
        q.save!
      end
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          expect(alignments.pluck(:title).include?(@quiz2.title)).to be true
        end
      end
    end

    it "deleted, the outcome alignments does not include the alignment to the quiz" do
      @bank.assessment_questions.each do |q|
        q.workflow_state = "deleted"
        q.save!
      end
      GraphQL::Batch.batch do
        Loaders::OutcomeAlignmentLoader.for(
          @course
        ).load(@outcome).then do |alignments|
          expect(alignments.pluck(:title).include?(@quiz2.title)).to be false
        end
      end
    end
  end
end
