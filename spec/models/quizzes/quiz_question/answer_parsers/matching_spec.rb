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

describe Quizzes::QuizQuestion::AnswerParsers::Matching do
  describe "#parse" do
    let(:raw_answers) do
      [
        {
          answer_text: "Answer 1",
          answer_match_left: "Answer 1",
          answer_match_right: "Match to Answer 1",
          answer_comment: "This is answer 1",
          answer_comment_html: '<img src="x" onerror="alert(1)">',
          answer_weight: 0
        },
        {
          answer_text: "Answer 2",
          answer_match_left: "Answer 2",
          answer_match_right: "Match to Answer 2",
          answer_comment: "This is answer 2",
          answer_weight: 100
        },
        {
          answer_text: "Answer 3",
          answer_match_left: "Answer 3",
          answer_match_right: "Match to Answer 3",
          answer_comment: "This is answer 3",
          answer_weight: 0
        }
      ]
    end

    let(:question_params) do
      {
        matching_answer_incorrect_matches: "",
        question_type: "matching_question"
      }
    end

    let(:parser_class) { Quizzes::QuizQuestion::AnswerParsers::Matching }

    let(:raw_dupe_answers) do
      [
        {
          answer_text: "Salt Lake City",
          answer_match_left: "Salt Lake City",
          answer_match_right: "Utah",
          answer_comment: "This is answer 1",
          answer_weight: 0
        },
        {
          answer_text: "San Diego",
          answer_match_left: "San Diego",
          answer_match_right: "California",
          answer_comment: "This is answer 2",
          answer_weight: 100
        },
        {
          answer_text: "Los Angeles",
          answer_match_left: "Los Angeles",
          answer_match_right: "California",
          answer_comment: "This is answer 3",
          answer_weight: 0
        }
      ]
    end

    include_examples "All answer parsers"

    it "reuses match_id for duplicate answer_match_right" do
      question = Quizzes::QuizQuestion::QuestionData.new(question_params)
      question.answers = Quizzes::QuizQuestion::AnswerGroup.new(raw_dupe_answers)
      parser = parser_class.new(question.answers)
      question = parser.parse(question)
      @answer_data = question.answers

      # usually match_ids are different
      expect(@answer_data[0][:match_id]).not_to eql @answer_data[1][:match_id]

      # but 2nd & 3rd are both "California" and should have the same :match_id
      expect(@answer_data[1][:match_id]).to eql @answer_data[2][:match_id]
    end
  end
end
