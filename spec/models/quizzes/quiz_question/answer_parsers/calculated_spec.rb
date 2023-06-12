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
#

require_relative "answer_parser_spec_helper"

describe Quizzes::QuizQuestion::AnswerParsers::Calculated do
  context "#parse" do
    let(:raw_answers) do
      [
        {
          variables: { "variable_0" => { name: "x", value: "9" } },
          answer_text: 14
        },
        {
          variables: { "variable_2" => { name: "z", value: "7" } },
          answer_text: 12
        }
      ]
    end
    let(:parser_class) { Quizzes::QuizQuestion::AnswerParsers::Calculated }
    let(:question_params) do
      {
        question_name: "Formula Question",
        question_type: "calculated_question",
        points_possible: 1,
        question_text: "What is 5 + [x]?",
        formulas: ["5+x"],
        variables: [
          { name: "x", min: 5, max: 10, scale: 0 },
          { name: "z", min: 5, max: 10, scale: 10 }
        ]
      }
    end

    before do
      @question = parser_class.new(Quizzes::QuizQuestion::AnswerGroup.new(raw_answers)).parse(Quizzes::QuizQuestion::QuestionData.new(question_params))
    end

    it "formats formulas for the question" do
      @question[:formulas].each do |formula|
        expect(formula).to be_a(Hash)
      end
    end

    it "formats variables for the question" do
      @question.answers.each do |answer|
        expect(answer[:variables]).to be_a(Array)
      end
    end

    it "handles 0 scale answers without any decimal values" do
      expect(@question.answers.first[:variables].first[:value]).to eq "9"
    end

    it "handles 10 scale answers with the right number of decimal values" do
      expect(@question.answers.to_a.last[:variables].first[:value]).to eq "7.0000000000"
    end
  end
end
