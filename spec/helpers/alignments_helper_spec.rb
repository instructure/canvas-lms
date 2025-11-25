# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "nokogiri"
require "feature_flag_helper"

describe AlignmentsHelper do
  include AlignmentsHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers
  include FeatureFlagHelper

  before(:once) do
    account_model
    assignment_model
  end

  let_once(:outcome) do
    @course.created_learning_outcomes.create!(title: "outcome")
  end

  let_once(:account_outcome) do
    @account.created_learning_outcomes.create!(title: "account outcome!")
  end

  let_once(:alignment) do
    tag = ContentTag.create(
      content: outcome,
      context: outcome.context,
      tag_type: "learning_outcome"
    )
    outcome.alignments << tag
    tag
  end

  let_once(:graded_alignment) do
    tag = ContentTag.create(
      content: @assignment,
      context: outcome.context,
      tag_type: "learning_outcome"
    )
    outcome.alignments << tag
    tag
  end

  describe "outcome_alignment_url" do
    context "without an alignment" do
      it "returns nil if context is an account" do
        expect(outcome_alignment_url(@account, account_outcome)).to be_nil
      end
    end

    context "with an alignment" do
      it "returns a url path" do
        expect(outcome_alignment_url(@account, account_outcome, alignment)).to be_truthy
      end
    end
  end

  describe "link_to_outcome_alignment" do
    context "without an alignment" do
      let(:string) { link_to_outcome_alignment(@course, outcome) }

      it "does not include an icon-* html class" do
        expect(string.include?("icon-")).to be_falsey
      end

      it "is a blank link tag" do
        html = Nokogiri::HTML5.fragment(string)
        expect(html.text).to be_blank
      end
    end

    context "with an alignment" do
      let(:string) do
        link_to_outcome_alignment(@course, outcome, alignment)
      end

      it "does not include an icon-* html class" do
        expect(string.include?("icon-")).to be_truthy
      end

      it "is a blank link tag" do
        html = Nokogiri::HTML5.fragment(string)
        expect(html.text).to eq(alignment.title)
      end
    end
  end

  describe "outcome_alignment_tag" do
    context "without an alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "includes an id of 'alignment_blank'" do
        expect(string.include?("alignment_blank")).to be_truthy
      end

      it "includes class alignment" do
        expect(html["class"].split).to include("alignment")
      end

      it "includes 1 data-* attribute" do
        expect(html.keys.select do |k|
          k.include?("data-")
        end).to include("data-url")
      end

      it "is hidden" do
        expect(html["style"]).to match(/display:\ none/)
      end
    end

    context "with an alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome, alignment) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "includes an id of 'alignment_{id}'" do
        expect(string.match(/alignment_#{alignment.id}/)).to be_truthy
      end

      it "has classes alignment & its content_type_class" do
        classes = html["class"].split
        expect(classes).to include("alignment", alignment.content_type_class)
      end

      it "data-ids & data-url attributes" do
        expect(html.keys.select do |k|
          k.include?("data-")
        end).to include("data-id", "data-url")
      end

      it "is not hidden" do
        expect(html["style"]).not_to match(/display:\ none/)
      end
    end

    context "with a graded alignment" do
      let(:string) { outcome_alignment_tag(@course, outcome, graded_alignment) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "includes html class 'also_assignment'" do
        classes = html["class"].split
        expect(classes).to include("also_assignment")
      end
    end

    context "with a rubric association" do
      before(:once) do
        rubric_association_model({
                                   purpose: "grading"
                                 })
      end

      let(:string) { outcome_alignment_tag(@course, outcome, graded_alignment) { nil } }
      let(:html) { Nokogiri::HTML5.fragment(string).children[0] }

      it "has html 'data-has-rubric-association' data attritbute" do
        expect(html.keys.find do |k|
          k.include?("data-has-rubric-association")
        end).to be_truthy
      end
    end
  end

  describe "#find_all_outcome_alignments" do
    before(:once) do
      course_model
    end

    let(:test_outcome) { @course.created_learning_outcomes.create!(title: "test outcome") }

    def create_alignment(outcome, content)
      outcome.alignments.create!(
        content:,
        content_type: content.class.name,
        context: @course,
        tag_type: "learning_outcome"
      )
    end

    def create_published_quiz_with_question(bank)
      question = AssessmentQuestion.create!(
        assessment_question_bank: bank,
        question_data: { question_text: "test" },
        workflow_state: "active"
      )

      quiz = Quizzes::Quiz.create!(context: @course, title: "test quiz")
      Quizzes::QuizQuestion.create!(quiz:, assessment_question: question)
      quiz.generate_quiz_data
      quiz.published_at = Time.zone.now
      quiz.workflow_state = "available"
      quiz.save!
      [question, quiz]
    end

    it "returns an empty array when outcome has no alignments" do
      expect(find_all_outcome_alignments(test_outcome, @course)).to eq([])
    end

    it "returns direct alignments only when no indirect or external alignments exist" do
      assignment = @course.assignments.create!(title: "test assignment")
      create_alignment(test_outcome, assignment)

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(1)
      expect(result.first).to be_a(AlignmentWithMetadata)
      expect(result.first.content).to eq(assignment)
      expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::DIRECT)
    end

    it "returns direct alignments for rubrics" do
      rubric = Rubric.create!(context: @course, title: "test rubric")
      create_alignment(test_outcome, rubric)

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(1)
      expect(result.first.content).to eq(rubric)
      expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::DIRECT)
    end

    it "returns direct alignments for assessment question banks" do
      bank = AssessmentQuestionBank.create!(context: @course, title: "test bank")
      create_alignment(test_outcome, bank)

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(1)
      expect(result.first.content).to eq(bank)
      expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::DIRECT)
    end

    it "returns indirect alignments for classic quizzes via question banks" do
      bank = AssessmentQuestionBank.create!(context: @course, title: "test bank")
      create_alignment(test_outcome, bank)

      _question, quiz = create_published_quiz_with_question(bank)

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(2)

      direct = result.find { |a| a.alignment_type == AlignmentWithMetadata::AlignmentTypes::DIRECT }
      expect(direct.content).to eq(bank)

      indirect = result.find { |a| a.alignment_type == AlignmentWithMetadata::AlignmentTypes::INDIRECT }
      expect(indirect).not_to be_nil
      expect(indirect.content).to eq(quiz.assignment)
    end

    it "does not return indirect alignments for deleted quiz questions" do
      bank = AssessmentQuestionBank.create!(context: @course, title: "test bank")
      create_alignment(test_outcome, bank)

      question = AssessmentQuestion.create!(
        assessment_question_bank: bank,
        question_data: { question_text: "test" },
        workflow_state: "deleted"
      )

      quiz = Quizzes::Quiz.create!(context: @course, title: "test quiz")
      Quizzes::QuizQuestion.create!(quiz:, assessment_question: question)
      quiz.generate_quiz_data
      quiz.published_at = Time.zone.now
      quiz.workflow_state = "available"
      quiz.save!

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(1)
      expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::DIRECT)
    end

    it "does not return indirect alignments for deleted assignments" do
      bank = AssessmentQuestionBank.create!(context: @course, title: "test bank")
      create_alignment(test_outcome, bank)

      _question, quiz = create_published_quiz_with_question(bank)
      quiz.assignment.update!(workflow_state: "deleted")

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(1)
      expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::DIRECT)
    end

    context "with new quizzes (outcome service)" do
      before do
        mock_feature_flag_on_account(:outcome_alignment_summary_with_new_quizzes, true)
      end

      def stub_os_alignments(outcome, assignment, artifact_type: "quizzes.quiz")
        os_alignments = {
          outcome.id.to_s => [
            {
              artifact_type:,
              associated_asset_type: "canvas.assignment.quizzes",
              associated_asset_id: assignment.id.to_s
            }
          ]
        }
        allow(self).to receive(:get_active_os_alignments).with(@course).and_return(os_alignments)
      end

      it "returns external alignments for new quizzes" do
        assignment = @course.assignments.create!(title: "new quiz", submission_types: "external_tool")
        stub_os_alignments(test_outcome, assignment)

        result = find_all_outcome_alignments(test_outcome, @course)

        expect(result.length).to eq(1)
        expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::EXTERNAL)
        expect(result.first.content).to eq(assignment)
      end

      it "returns external alignments for new quiz items" do
        assignment = @course.assignments.create!(title: "new quiz", submission_types: "external_tool")
        stub_os_alignments(test_outcome, assignment, artifact_type: "quizzes.item")

        result = find_all_outcome_alignments(test_outcome, @course)

        expect(result.length).to eq(1)
        expect(result.first.alignment_type).to eq(AlignmentWithMetadata::AlignmentTypes::EXTERNAL)
      end

      it "does not return external alignments when feature flag is disabled" do
        mock_feature_flag_on_account(:outcome_alignment_summary_with_new_quizzes, false)

        assignment = @course.assignments.create!(title: "new quiz", submission_types: "external_tool")
        stub_os_alignments(test_outcome, assignment)

        expect(find_all_outcome_alignments(test_outcome, @course)).to eq([])
      end

      it "filters out unsupported artifact types" do
        assignment = @course.assignments.create!(title: "new quiz", submission_types: "external_tool")
        stub_os_alignments(test_outcome, assignment, artifact_type: "unsupported.type")

        expect(find_all_outcome_alignments(test_outcome, @course)).to eq([])
      end

      it "does not return external alignments for deleted assignments" do
        assignment = @course.assignments.create!(
          title: "new quiz",
          submission_types: "external_tool",
          workflow_state: "deleted"
        )
        stub_os_alignments(test_outcome, assignment)

        expect(find_all_outcome_alignments(test_outcome, @course)).to eq([])
      end
    end

    it "returns unique alignments when combining all types" do
      assignment = @course.assignments.create!(title: "test assignment")
      bank = AssessmentQuestionBank.create!(context: @course, title: "test bank")

      create_alignment(test_outcome, assignment)
      create_alignment(test_outcome, bank)

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(2)
      expect(result.uniq.length).to eq(2)
    end

    it "deduplicates alignments from different sources" do
      bank = AssessmentQuestionBank.create!(context: @course, title: "test bank")
      create_alignment(test_outcome, bank)

      _question, quiz = create_published_quiz_with_question(bank)
      create_alignment(test_outcome, quiz.assignment)

      result = find_all_outcome_alignments(test_outcome, @course)

      expect(result.length).to eq(3)

      assignment_alignments = result.select { |a| a.content == quiz.assignment }
      expect(assignment_alignments.length).to eq(2)
    end
  end
end
