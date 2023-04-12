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

describe Quizzes::QuizQuestion::MultipleDropdownsQuestion do
  let(:question_data) do
    {
      id: "1",
      answers: [{ id: 2, blank_id: "test_group", wieght: 100 }]
    }
  end

  let(:question) do
    Quizzes::QuizQuestion::MultipleDropdownsQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      expect(question.question_id).to eq question_data[:id]
    end
  end

  describe "#find_chosen_answer" do
    it "detects answers when answer id is an integer" do
      answer = question.find_chosen_answer("test_group", "2")
      expect(answer[:id]).to eq question_data[:answers][0][:id]
      expect(answer[:blank_id]).to eq question_data[:answers][0][:blank_id]
    end

    it "detects answers when answer id is a string" do
      question_data[:answers][0][:id] = "3"
      question = Quizzes::QuizQuestion::MultipleDropdownsQuestion.new(question_data)
      answer = question.find_chosen_answer("test_group", "3")
      expect(answer[:id]).to eq question_data[:answers][0][:id]
      expect(answer[:blank_id]).to eq question_data[:answers][0][:blank_id]
    end

    it "returns nil values when answer not detected" do
      answer = question.find_chosen_answer("test_group", "0")
      expect(answer[:id]).to be_nil
      expect(answer[:blank_id]).to be_nil
    end
  end
end
