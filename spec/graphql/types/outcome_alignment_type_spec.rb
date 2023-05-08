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

require_relative "../graphql_spec_helper"
require_relative "../../spec_helper"
require_relative "../../outcome_alignments_spec_helper"

describe Types::OutcomeAlignmentType do
  before :once do
    account_admin_user
    course_model
    outcome_with_rubric
    @quiz_item = assignment_quiz([], course: @course, title: "BBB Quiz")
    @quiz = @assignment
    @assignment = @course.assignments.create!(title: "AAA Assignment")
    @discussion = @course.assignments.create!(title: "CCC Graded Discussion")
    @course.discussion_topics.create!(
      user: @teacher,
      title: "CCC discussion item",
      assignment: @discussion
    )
    @module = @course.context_modules.create!(name: "module")
    @course.account.enable_feature!(:improved_outcomes_management)
  end

  let(:graphql_context) { { current_user: @admin } }
  let(:outcome_type) { GraphQLTypeTester.new(@outcome, graphql_context) }

  def resolve_field(field_name, result_index: 0)
    outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { #{field_name} }")[result_index]
  end

  describe "for direct outcome alignments to assignment, quiz and graded discussion" do
    before do
      @module.add_item type: "assignment", id: @assignment.id
      @rubric.associate_with(@assignment, @course, purpose: "grading")
      @outcome_alignment = ContentTag.last
    end

    it "returns _id like D_{alignment_id}_{module_id}" do
      expect(resolve_field("_id")).to eq ["D", @outcome_alignment.id.to_s, @module.id.to_s].join("_")
    end

    it "returns learning_outcome_id" do
      expect(resolve_field("learningOutcomeId")).to eq @outcome.id.to_s
    end

    it "returns context_id" do
      expect(resolve_field("contextId")).to eq @course.id.to_s
    end

    it "returns context_type" do
      expect(resolve_field("contextType")).to eq "Course"
    end

    it "returns content_id" do
      expect(resolve_field("contentId")).to eq @outcome_alignment.content_id.to_s
    end

    it "returns content_type" do
      expect(resolve_field("contentType")).to eq "Assignment"
    end

    it "returns title" do
      expect(resolve_field("title")).to eq @assignment.title
    end

    it "returns url" do
      expect(resolve_field("url")).to eq "/courses/#{@course.id}/assignments/#{@assignment.id}"
    end

    it "returns module_id" do
      expect(resolve_field("moduleId")).to eq @module.id.to_s
    end

    it "returns module_name" do
      expect(resolve_field("moduleName")).to eq @module.name
    end

    it "returns module_url" do
      expect(resolve_field("moduleUrl")).to eq "/courses/#{@course.id}/modules/#{@module.id}"
    end

    it "returns module_workflow_state" do
      expect(resolve_field("moduleWorkflowState")).to eq @module.workflow_state
    end

    it "returns quizItems" do
      expect(resolve_field("quizItems { _id }")).to be_nil
    end

    it "returns alignmentsCount" do
      expect(resolve_field("alignmentsCount")).to eq 1
    end
  end

  describe "for outcome alignment not included in module" do
    before do
      @rubric.associate_with(@assignment, @course, purpose: "grading")
      @outcome_alignment = ContentTag.last
    end

    it "returns _id not appended with module_id" do
      expect(resolve_field("_id")).to eq ["D", @outcome_alignment.id.to_s].join("_")
    end
  end

  describe "for outcome alignment to an Assignment" do
    before do
      @assignment.unpublish
      @rubric.associate_with(@assignment, @course, purpose: "grading")
    end

    it "returns assignment_content_type 'assignment'" do
      expect(resolve_field("assignmentContentType")).to eq "assignment"
    end

    it "returns the workflow state of the assignment in assignment_workflow_state" do
      expect(resolve_field("assignmentWorkflowState")).to eq @assignment.workflow_state
    end
  end

  describe "for outcome alignment to a Quiz" do
    before do
      @rubric.associate_with(@quiz, @course, purpose: "grading")
    end

    it "returns assignment_content_type 'quiz'" do
      expect(resolve_field("assignmentContentType")).to eq "quiz"
    end

    it "returns the workflow state of the quiz in assignment_workflow_state" do
      expect(resolve_field("assignmentWorkflowState")).to eq @quiz.workflow_state
    end
  end

  describe "for indirect outcome alignment to Quiz via question bank" do
    before do
      assessment_question_bank_with_questions
      @outcome.align(@bank, @bank.context)
      @quiz2 = assignment_quiz([], course: @course, title: "DDD quiz with questions from questions bank")
      @quiz2_assignment = @assignment
      @quiz2.add_assessment_questions [@q1, @q2]
      @module.add_item type: "quiz", id: @quiz2.id
    end

    it "returns _id like I_{quiz_assignment_id}_{module_id}" do
      expect(resolve_field("_id")).to eq ["I", @quiz2_assignment.id.to_s, @module.id.to_s].join("_")
    end

    it "returns assignment_content_type 'quiz'" do
      expect(resolve_field("assignmentContentType")).to eq "quiz"
    end
  end

  describe "for outcome alignment to a Graded Discussion" do
    before do
      @rubric.associate_with(@discussion, @course, purpose: "grading")
    end

    it "returns assignment_content_type 'discussion'" do
      expect(resolve_field("assignmentContentType")).to eq "discussion"
    end

    it "returns the workflow state of the discussion in assignment_workflow_state" do
      expect(resolve_field("assignmentWorkflowState")).to eq @discussion.workflow_state
    end
  end

  describe "for outcome alignment to a Rubric" do
    it "returns null assignment_content_type" do
      expect(resolve_field("assignmentContentType")).to be_nil
    end

    it "returns url for the rubric" do
      expect(resolve_field("url")).to eq "/courses/#{@course.id}/rubrics/#{@rubric.id}"
    end
  end

  describe "for outcome alignment to a Question Bank" do
    before do
      assessment_question_bank_model
      @bank.title = "EEE question bank"
      @bank.save!
      @outcome.align(@bank, @bank.context)
    end

    it "returns url for the question bank" do
      expect(resolve_field("url")).to eq "/courses/#{@course.id}/question_banks/#{@bank.id}"
    end
  end

  describe "for outcome alignments to New Quiz" do
    before do
      @course.enable_feature!(:outcome_alignment_summary_with_new_quizzes)
      @new_quiz = @course.assignments.create!(title: "new quiz - aligned in OS", submission_types: "external_tool")
      @module.add_item type: "assignment", id: @new_quiz.id
      allow_any_instance_of(OutcomesServiceAlignmentsHelper)
        .to receive(:get_os_aligned_outcomes)
        .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id))
    end

    it "returns assignment_content_type 'new_quiz'" do
      expect(resolve_field("assignmentContentType", result_index: 1)).to eq "new_quiz"
    end

    context "when outcome is aligned only to the quiz" do
      it "returns empty list of quizItems" do
        expect(resolve_field("quizItems { _id, title}", result_index: 1)).to eq []
      end

      it "calculates properly alignmentCount" do
        expect(resolve_field("alignmentsCount", result_index: 1)).to eq 1
      end
    end

    context "when outcome is aligned to both the quiz and to quiz items" do
      before do
        allow_any_instance_of(OutcomesServiceAlignmentsHelper)
          .to receive(:get_os_aligned_outcomes)
          .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id, with_items: true))
      end

      it "returns list of aligned quiz items" do
        expect(resolve_field("quizItems { _id, title}", result_index: 1).length).to be 2
        expect(resolve_field("quizItems {_id}", result_index: 1)).to match_array(["101", "102"])
        expect(resolve_field("quizItems {title}", result_index: 1)).to match_array(["Question Number 101", "Question Number 102"])
      end

      it "calculates properly alignmentsCount" do
        expect(resolve_field("alignmentsCount", result_index: 1)).to eq 3
      end
    end

    context "when outcome is aligned only to quiz items" do
      before do
        allow_any_instance_of(OutcomesServiceAlignmentsHelper)
          .to receive(:get_os_aligned_outcomes)
          .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id, with_quiz: false, with_items: true))
      end

      it "returns list of aligned quiz items" do
        expect(resolve_field("quizItems { _id, title}", result_index: 1).length).to be 2
        expect(resolve_field("quizItems {_id}", result_index: 1)).to match_array(["101", "102"])
        expect(resolve_field("quizItems {title}", result_index: 1)).to match_array(["Question Number 101", "Question Number 102"])
      end

      it "calculates properly alignmentCount" do
        expect(resolve_field("alignmentsCount", result_index: 1)).to eq 2
      end
    end
  end
end
