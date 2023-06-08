# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class TestableApiQuizQuestion
  class << self
    include Api::V1::QuizQuestion

    def api_user_content(html, *_)
      html
    end
  end
end

describe Api::V1::QuizQuestion do
  describe ".question_json" do
    subject do
      TestableApiQuizQuestion.question_json(
        question, user, session, context, includes, censored, quiz_data, opts
      )
    end

    let(:answers) { [] }
    let(:question_data) { { "answers" => answers } }
    let(:question) { Quizzes::QuizQuestion.new(question_data:) }
    let(:user) { User.new }
    let(:session) { nil }
    let(:context) { nil }
    let(:includes) { [] }
    let(:censored) { false }
    let(:quiz_data) { nil }
    let(:opts) { {} }

    it { is_expected.to include("question_name" => "Question") }
    it { is_expected.to include("question_type" => "text_only_question") }
    it { is_expected.to include("question_text" => "Question text") }
    it { is_expected.to include("points_possible") }
    it { is_expected.to include("correct_comments") }
    it { is_expected.to include("incorrect_comments") }
    it { is_expected.to include("neutral_comments") }
    it { is_expected.to include("correct_comments_html") }
    it { is_expected.to include("incorrect_comments_html") }
    it { is_expected.to include("neutral_comments_html") }
    it { is_expected.to include("answers") }
    it { is_expected.to include("variables") }
    it { is_expected.to include("formulas") }
    it { is_expected.to include("answer_tolerance") }
    it { is_expected.to include("formula_decimal_places") }
    it { is_expected.to include("matches") }
    it { is_expected.to include("matching_answer_incorrect_matches") }

    context "with bogus question data" do
      let(:question_data) do
        {
          "answers" => answers,
          "bogus" => "bogus"
        }
      end

      it { is_expected.not_to include("bogus") }
    end

    context "with quiz_data" do
      let(:quiz_data) do
        [{
          "id" => question[:id],
          "question_type" => "some_other_type",
          "answers" => answers,
          "position" => 4
        }]
      end

      it { is_expected.to include("question_type" => "some_other_type") }
      it { is_expected.to include("position" => 4) }
    end
  end

  describe "as a student" do
    subject { TestableApiQuizQuestion.question_json(question, user, session, nil, [], true) }

    let(:answers) { [] }
    let(:question) { Quizzes::QuizQuestion.new(question_data:) }
    let(:user) { User.new }
    let(:session) { nil }

    describe "text_only_questions" do
      let(:question_data) { { "answers" => answers, "question_type" => "text_only_questions" } }

      it { is_expected.not_to include("answers") }
      it { is_expected.not_to include("matching_answer_incorrect_matches") }
      it { is_expected.not_to include("points_possible") }
      it { is_expected.not_to include("correct_comments") }
      it { is_expected.not_to include("incorrect_comments") }
      it { is_expected.not_to include("neutral_comments") }
      it { is_expected.not_to include("correct_comments_html") }
      it { is_expected.not_to include("incorrect_comments_html") }
      it { is_expected.not_to include("neutral_comments_html") }
      it { is_expected.to include("variables") }
      it { is_expected.to include("answer_tolerance") }
      it { is_expected.to include("formula_decimal_places") }
      it { is_expected.to include("formulas") }
      it { is_expected.to include("question_name" => "Question") }
      it { is_expected.to include("question_type" => "text_only_questions") }
      it { is_expected.to include("question_text" => "Question text") }
      it { is_expected.to include("matches") }
    end

    describe "calculated_questions" do
      let(:question_data) { { "answers" => answers, "question_type" => "calculated_question" } }

      it { is_expected.to include("answers") }
      it { is_expected.to include("variables") }
      it { is_expected.to include("formulas") }
      it { is_expected.to include("answer_tolerance") }
      it { is_expected.to include("formula_decimal_places") }
    end

    describe "multiple_dropdowns_question" do
      let(:question_data) { { "answers" => answers, "question_type" => "multiple_dropdowns_question" } }

      it { is_expected.to include("answers") }
    end
  end

  describe "regrade_option" do
    let(:account) { Account.create! }
    let(:user) { User.create }
    let(:course) { Course.create!(account:) }
    let(:quiz) do
      quiz = course.quizzes.create!(title: "Quiz")
      quiz.publish!
      quiz
    end

    let(:question) do
      quiz.quiz_questions.create!(question_data: { "name" => "test question 1", "answers" => [{ "id" => 1 }, { "id" => 2 }], :position => 1 })
    end

    context "when a valid regrade_option is passed" do
      it "creates regrades with the regrade_option" do
        question.question_data = { regrade_option: "full_credit", regrade_user: user }
        expect(quiz.current_quiz_question_regrades.first.regrade_option).to eq "full_credit"
      end
    end

    context "when an invalid regrade_option is passed" do
      it "creates no regrades" do
        question.question_data = { regrade_option: "false", regrade_user: user }
        expect(quiz.current_quiz_question_regrades.count).to be 0
      end
    end
  end
end
