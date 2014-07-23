#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

RSpec::Matchers.define :have_question_field do |expected|
  match do |question_data|
    question_data.key? expected
  end
end

describe Quizzes::QuizQuestion::QuestionData do
  let(:question_data_params) do
    {
      answers: [],
      regrade_option: false,
      points_possible: 5,
      correct_comments: "This question is correct.",
      incorrect_comments: "This question is correct.",
      neutral_comments: "Answer this question.",
      question_name: "Generic question",
      question_text: "What is better, ruby or javascript?"
    }
  end


  describe '.generate' do
    it "returns an instance of QuestionData" do
      question = Quizzes::QuizQuestion::QuestionData.generate

      question.should be_kind_of(Quizzes::QuizQuestion::QuestionData)
    end

    it "defaults to text_only_question if a type isn't given" do
      question = Quizzes::QuizQuestion::QuestionData.generate

      question[:question_type].should == 'text_only_question'
      question.is_type?(:text_only).should be_true
    end

    context "on any question type" do
      let(:question_data) { Quizzes::QuizQuestion::QuestionData.generate }
      context "it seeds QuestionData with" do
        it "regrade_option" do
          question_data.should have_question_field :regrade_option
        end

        it "points_possible" do
          question_data.should have_question_field :points_possible
        end

        it "correct_comments" do
          question_data.should have_question_field :correct_comments
        end

        it "incorrect_comments" do
          question_data.should have_question_field :incorrect_comments
        end

        it "neutral_comments" do
          question_data.should have_question_field :neutral_comments
        end

        it "question_type" do
          question_data.should have_question_field :question_type
        end

        it "question_name" do
          question_data.should have_question_field :question_name
        end

        it "question_text" do
          question_data.should have_question_field :question_text
        end

        it "answers" do
          question_data.should have_question_field :answers
        end

        it "text_after_answers" do
          question_data.should have_question_field :text_after_answers
        end
      end
    end

    context "of 'calculated' type" do
      let(:question_data) { Quizzes::QuizQuestion::QuestionData.generate(question_type: 'calculated_question') }
      context "it seeds QuestionData with" do
        it "formulas" do
          question_data.should have_question_field :formulas
        end

        it "variables" do
          question_data.should have_question_field :variables
        end

        it "answer_tolerance" do
          question_data.should have_question_field :answer_tolerance
        end

        it "formula_decimal_places" do
          question_data.should have_question_field :formula_decimal_places
        end
      end
    end

    context "of 'matching' type" do
      let(:question_data) { Quizzes::QuizQuestion::QuestionData.generate(question_type: 'matching_question') }
      context "it seeds QuestionData with" do
        it "matching_answer_incorrect_matches" do
          question_data.should have_question_field :matching_answer_incorrect_matches
        end

        it "matches" do
          question_data.should have_question_field :matches
        end
      end
    end

  end


  describe "#to_hash" do
    it "returns an indifferent hash" do
      question = Quizzes::QuizQuestion::QuestionData.generate

      question.to_hash.should be_kind_of(HashWithIndifferentAccess)
    end
  end

  describe "#answer_parser" do
    context "returns the relevant parser for" do
      it "calculated questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'calculated_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::Calculated
      end

      it "essay questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'essay_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::Essay
      end

      it "fill in multiple blanks questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'fill_in_multiple_blanks_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::FillInMultipleBlanks
      end

      it "matching questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'matching_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::Matching
      end

      it "missing word questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'missing_word_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::MissingWord
      end

      it "multiple answer questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'multiple_answers_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::MultipleAnswers
      end

      it "multiple choice questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'multiple_choice_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::MultipleChoice
      end

      it "multiple dropdown questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'multiple_dropdowns_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::MultipleDropdowns
      end

      it "numerical questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'numerical_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::Numerical
      end

      it "short answer questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'short_answer_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::ShortAnswer
      end

      it "text only questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'text_only_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::TextOnly
      end

      it "true/false questions" do
        question = Quizzes::QuizQuestion::QuestionData.generate(question_type: 'true_false_question')
        question.answer_parser.should == Quizzes::QuizQuestion::AnswerParsers::TrueFalse
      end

    end
  end
end
