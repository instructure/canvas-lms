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

describe Quizzes::QuizQuestion::FillInMultipleBlanksQuestion do
  let(:answer1) { { id: 1, blank_id: "blank1", text: "First", weight: 100 } }
  let(:answer2) { { id: 2, blank_id: "blank2", text: "Second", weight: 100 } }
  let(:question) { Quizzes::QuizQuestion::FillInMultipleBlanksQuestion.new(answers: [answer1, answer2]) }

  describe "#find_chosen_answer" do
    it "compares answers in downcase" do
      expect(question.find_chosen_answer("blank1", "FIRST")[:id]).to eq answer1[:id]
    end

    it "only considers answers for the same blank" do
      expect(question.find_chosen_answer("blank1", "Second")[:id]).to be_nil
    end

    it "retains the casing in the provided response for correct answers" do
      expect(question.find_chosen_answer("blank1", "FIRST")[:text]).to eq "FIRST"
    end

    it "does not alter the answer object's casing in correct answers" do
      question.find_chosen_answer("blank1", "FIRST")
      expect(answer1[:text]).to eq "First"
    end

    it "retains the casing in the provided response for incorrect answers" do
      expect(question.find_chosen_answer("blank1", "Wrong")[:text]).to eq "Wrong"
    end

    it "replaces nil with an empty string" do
      expect(question.find_chosen_answer("blank1", nil)[:text]).to eq ""
    end
  end
end
