# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Quizzes::QuizQuestion::NumericalQuestion do
  let(:question_data) do
    { answers: [{ id: 1, weight: 100, start: 2, end: 3 }] }
  end

  let(:question) do
    Quizzes::QuizQuestion::NumericalQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      expect(question.question_id).to eq question_data[:id]
    end
  end

  describe "#i18n_decimal" do
    it "works in english" do
      expect(question.i18n_decimal("1234.56")).to eq BigDecimal("1234.56")
      expect(question.i18n_decimal("1,234.56")).to eq BigDecimal("1234.56")
    end

    it "works in french" do
      I18n.with_locale(:fr) do
        expect(question.i18n_decimal("1 234,56")).to eq BigDecimal("1234.56")
        expect(question.i18n_decimal("1234,56")).to eq BigDecimal("1234.56")
      end
    end

    it "works for inputs of type Integer" do
      expect(question.i18n_decimal(1234)).to eq BigDecimal("1234")
    end

    it "works for inputs of type Float" do
      expect(question.i18n_decimal(123_456e-2)).to eq BigDecimal("1234.56")
    end
  end

  describe "#correct_answer_parts" do
    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    context "handles '' values without error" do
      it 'handles "answer[:exact]"' do
        answer_data = {
          numerical_answer_type: "exact_answer"
        }
        user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
        expect { question.correct_answer_parts(user_answer) }.not_to raise_error
      end

      it 'handles "answer[:approximate]"' do
        answer_data = {
          numerical_answer_type: "precision_answer"
        }
        user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
        expect { question.correct_answer_parts(user_answer) }.not_to raise_error
      end
    end

    it "does not calculate margin of tolerance for answers if answer text is nil" do
      answer_data = { "question_#{question_id}": nil }
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
      expect(question.correct_answer_parts(user_answer)).to be_nil
    end

    it "does not calculate margin of tolerance for answers if answer text is blank" do
      answer_data = { "question_#{question_id}": "" }
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
      expect(question.correct_answer_parts(user_answer)).to be_falsey
    end

    it "calculates if answer falls within start/end range" do
      answer_data = { "question_#{question_id}": "2.5" }
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end

    it "calculates if answer falls out of start/end range" do
      answer_data = { "question_#{question_id}": "4" }
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_falsey
    end

    describe "flexible ranges" do # rubocop:disable RSpec/EmptyExampleGroup
      # RuboCop can't detect the examples that are dynamically defined
      def self.test_range(range, answer, is_correct)
        desc = "should calculate if %s falls %s (%d,%d)" % [
          answer, is_correct ? "within" : "out of", range[0], range[1]
        ]

        it desc do
          answer_data = { "question_#{question_id}": answer.to_s }
          question = Quizzes::QuizQuestion::NumericalQuestion.new({
                                                                    answers: [{
                                                                      id: 1,
                                                                      weight: 100,
                                                                      start: range[0],
                                                                      end: range[1]
                                                                    }]
                                                                  })

          user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
          expect(question.correct_answer_parts(user_answer)).to eq is_correct
        end
      end

      test_range [-3, 3], -2.5, true
      test_range [3, -3], -2.5, true
      test_range [-3, 3], -3.5, false
      test_range [3, -3], -3.5, false
      test_range [2.5, 3.5], 2.5, true
      test_range [2.5, 3.5], 2.49, false
      test_range [100, 50], 75, true
      test_range [50, 100], 75, true
    end
  end
end
