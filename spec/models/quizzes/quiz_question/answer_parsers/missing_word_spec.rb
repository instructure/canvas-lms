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

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/answer_parser_spec_helper.rb')


describe Quizzes::QuizQuestion::AnswerParsers::MissingWord do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe "#parse" do
    let(:raw_answers) do
      [
        {
          answer_text: "Answer 1",
          answer_comments: "This is answer 1",
          answer_weight: 0,
          text_after_answers: "Text after Answer 1"
        },
        {
          answer_text: "Answer 2",
          answer_comments: "This is answer 2",
          answer_weight: 100,
          text_after_answers: "Text after Answer 2"
        },
        {
          answer_text: "Answer 3",
          answer_comments: "This is answer 3",
          answer_weight: 0,
          text_after_answers: "Text after Answer 3"
        }
      ]
    end

    let(:question_params) { Hash.new }
    let(:parser_class) { Quizzes::QuizQuestion::AnswerParsers::MissingWord }

    context "in general" do
      include_examples "All answer parsers"
    end

    context "with no answer specified as correct" do
      let(:unspecified_answers) { raw_answers.map { |a| a[:answer_weight] = 0; a } }

      before(:each) do
        question = Quizzes::QuizQuestion::QuestionData.new({})
        question.answers = Quizzes::QuizQuestion::AnswerGroup.new(unspecified_answers)
        parser = Quizzes::QuizQuestion::AnswerParsers::MissingWord.new(question.answers)
        question = parser.parse(question)
        @answer_data = question.answers
      end

      it "defaults to the first answer being correct" do
        expect(@answer_data.answers.first[:weight]).to eq 100
      end

    end

  end
end
