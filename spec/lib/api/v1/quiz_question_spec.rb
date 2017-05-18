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

require 'spec_helper'

class TestableApiQuizQuestion
  class << self
    include Api::V1::QuizQuestion

    def api_user_content(html, *_)
      html
    end
  end
end

describe Api::V1::QuizQuestion do
  describe '.question_json' do
    let(:answers) { [] }
    let(:question_data) { { "answers" => answers } }
    let(:question) { Quizzes::QuizQuestion.new(question_data: question_data) }
    let(:user) { User.new }
    let(:session) { nil }

    subject { TestableApiQuizQuestion.question_json(question, user, session) }

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

    context 'with bogus question data' do
      let(:question_data) do
        {
          "answers" => answers,
          "bogus" => "bogus"
        }
      end

      it { is_expected.not_to include("bogus") }
    end
  end

  describe 'as a student' do
    let(:answers) { [] }
    let(:question) { Quizzes::QuizQuestion.new(question_data: question_data) }
    let(:user) { User.new }
    let(:session) { nil }

    subject { TestableApiQuizQuestion.question_json(question, user, session, nil, [], true) }

    describe 'text_only_questions' do
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
      it { is_expected.not_to include("answers") }
      it { is_expected.to include("variables") }
      it { is_expected.to include("answer_tolerance") }
      it { is_expected.to include("formula_decimal_places") }
      it { is_expected.to include("formulas") }
      it { is_expected.to include("question_name" => "Question") }
      it { is_expected.to include("question_type" => "text_only_questions") }
      it { is_expected.to include("question_text" => "Question text") }
      it { is_expected.to include("matches") }
    end

    describe 'calculated_questions' do
      let(:question_data) { { "answers" => answers, "question_type" => "calculated_question" } }
      it { is_expected.to include("answers") }
      it { is_expected.to include("variables") }
      it { is_expected.to include("formulas") }
      it { is_expected.to include("answer_tolerance") }
      it { is_expected.to include("formula_decimal_places") }
    end

    describe 'multiple_dropdowns_question' do
      let(:question_data) { { "answers" => answers, "question_type" => "multiple_dropdowns_question" } }
      it { is_expected.to include("answers") }
    end
  end
end
