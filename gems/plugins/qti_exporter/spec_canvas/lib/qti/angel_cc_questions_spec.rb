# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../qti_helper"
if Qti.migration_executable
  describe "Converting Angel CC QTI" do
    it "converts multiple choice" do
      manifest_node = get_manifest_node("multiple_choice")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: angel_question_dir)
      hash[:answers].each { |a| a.delete(:id) }
      expect(hash).to eq AngelExpected::MULTIPLE_CHOICE
    end

    it "converts true false" do
      manifest_node = get_manifest_node("true_false")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: angel_question_dir)
      hash[:answers].each { |a| a.delete(:id) }
      expect(hash).to eq AngelExpected::TRUE_FALSE
    end

    it "converts multiple response" do
      manifest_node = get_manifest_node("multiple_answer")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: angel_question_dir)
      hash[:answers].each { |a| a.delete(:id) }
      expect(hash).to eq AngelExpected::MULTIPLE_ANSWER
    end

    it "converts essay" do
      manifest_node = get_manifest_node("essay")
      hash = Qti::ChoiceInteraction.create_instructure_question(manifest_node:, base_dir: angel_question_dir)
      expect(hash).to eq AngelExpected::ESSAY
    end

    it "converts the assessment into a quiz" do
      manifest_node = get_manifest_node("assessment", quiz_type: "Test")
      a = Qti::AssessmentTestConverter.new(manifest_node, angel_question_dir)
      a.create_instructure_quiz
      expect(a.quiz).to eq AngelExpected::ASSESSMENT
    end
  end

  module AngelExpected
    MULTIPLE_CHOICE =
      { correct_comments: "You got it! Majority rules in QM rubric scoring. Since two out of the three reviewers scored the standard \"No,\" no points are awarded for this standard.",
        question_name: "",
        migration_id: "543c53e4-f001-41a7-af6d-3312572801d3",
        answers: [{ migration_id: "answerChoice1",
                    weight: 0,
                    text: "3 points" },
                  { migration_id: "answerChoice2",
                    weight: 0,
                    text: "2 points" },
                  { migration_id: "answerChoice3",
                    weight: 0,
                    text: "1 point" },
                  { migration_id: "answerChoice4",
                    weight: 100,
                    text: "0 points" }],
        incorrect_comments: "If you chose one of the incorrect answers, you may have been thinking that the scores were averaged or that the master reviewer's \"Yes\" score carried more weight than the other reviewers' scores. Majority rules in QM rubric scoring. Since two out of the three reviewers scored the standard \"No,\" no points are awarded for this standard.",
        points_possible: 1,
        question_type: "multiple_choice_question",
        question_text: "A peer review team is reviewing a course.  They are considering Standard 1.1.  Reviewer 1 scores the standard \"No.\"  Reviewer 2 scores the standard \"No.\" The Master Reviewer scores the standard \"Yes.\" How many points will the course receive for Standard 1.1?" }.freeze
    TRUE_FALSE =
      { question_type: "multiple_choice_question",
        migration_id: "0ee472e8-5bc2-4b30-a341-2fa93a50bc54",
        question_text: "If a course meets expectations, it is recognized on the QM website and permitted to display the QM logo.",
        answers: [{ migration_id: "true", text: "True", weight: 100 },
                  { migration_id: "false", text: "False", weight: 0 }],
        incorrect_comments: "",
        correct_comments: "",
        points_possible: 1,
        question_name: "" }.freeze

    MULTIPLE_ANSWER =
      { points_possible: 1,
        question_name: "",
        question_type: "multiple_answers_question",
        answers: [{ migration_id: "answerChoice1",
                    text: "A subject matter expert",
                    weight: 100 },
                  { migration_id: "answerChoice2",
                    text: "An external reviewer",
                    weight: 100 },
                  { migration_id: "answerChoice3",
                    text: "An instructional designer",
                    weight: 0 },
                  { migration_id: "answerChoice4", text: "A student", weight: 0 },
                  { migration_id: "answerChoice5",
                    text: "A master reviewer",
                    weight: 100 }],
        migration_id: "f2e9bd5b-8dae-4829-a639-c38e97a96c62",
        question_text: "The QM peer review team must be composed of which of the following (select all that apply)?",
        incorrect_comments: "The QM peer review team must include a subject matter expert, an external reviewer, and a master reviewer. While an instructional designer may be involved in preparing the course for review or may happen to be one of the reviewers, QM does not require that an instructional designer be part of the review team. Likewise, while the peer reviewers examine the course from the perspective of a student, students do not review the course in a QM review.",
        correct_comments: "Correct! The QM peer review team must include a subject matter expert, an external reviewer, and a master reviewer." }.freeze
    ESSAY =
      { incorrect_comments: "",
        correct_comments: "",
        points_possible: 1,
        answers: [],
        question_name: "",
        question_type: "essay_question",
        migration_id: "f6129250-3baf-4128-8c81-efc5d495eef1",
        question_text: "Explain what happens when a course meets expectations and when a course does not meet expectations." }.freeze
    ASSESSMENT =
      { grading: { grade_type: "numeric",
                   migration_id: "angel2_assessment",
                   due_date: nil,
                   weight: nil,
                   title: "QM Practice Quiz",
                   points_possible: "237.0" },
        question_count: 8,
        migration_id: "angel2_assessment",
        quiz_name: "QM Practice Quiz",
        quiz_type: "assignment",
        title: "QM Practice Quiz",
        questions: [{ question_type: "question_reference",
                      migration_id: "ID_622cb516-53e7-44ee-aad1-9998a8395b3b" },
                    { question_type: "question_reference",
                      migration_id: "f2e9bd5b-8dae-4829-a639-c38e97a96c62" },
                    { question_type: "question_reference",
                      migration_id: "ID_9c0075c8-fc10-43d2-834c-ba630f44e21d" },
                    { question_type: "question_reference",
                      migration_id: "ID_4ca73eba-edbb-4cad-87f5-d0aa2284440c" },
                    { question_type: "question_reference",
                      migration_id: "ID_543c53e4-f001-41a7-af6d-3312572801d3" },
                    { question_type: "question_reference",
                      migration_id: "b00fe68d-2b75-4652-8d06-9e9d38a1fef6" },
                    { question_type: "question_reference",
                      migration_id: "ID_0ee472e8-5bc2-4b30-a341-2fa93a50bc54" },
                    { question_type: "question_reference",
                      migration_id: "ID_3f9f4eed-4698-4690-9f9d-851b31ce5eb0" }],
        points_possible: "237.0" }.freeze
  end
end
