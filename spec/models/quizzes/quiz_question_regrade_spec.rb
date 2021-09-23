# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizQuestionRegrade do

  describe "relationships" do

    it "belongs to a quiz_question" do
      expect(Quizzes::QuizQuestionRegrade.new).to respond_to :quiz_question
    end

    it "belongs to a quiz_regrade" do
      expect(Quizzes::QuizQuestionRegrade.new).to respond_to :quiz_regrade
    end
  end

  describe "validations" do

    it "validates the presence of quiz_question_id & quiz_regrade_id" do
      expect(Quizzes::QuizQuestionRegrade.new).not_to be_valid
      expect(Quizzes::QuizQuestionRegrade.new(quiz_question_id: 1, quiz_regrade_id: 1)).to be_valid
    end
  end

  describe "#question_data" do
    it "should delegate to quiz question" do
      question = Quizzes::QuizQuestion.new
      allow(question).to receive_messages(:question_data => "foo")

      qq_regrade = Quizzes::QuizQuestionRegrade.new
      qq_regrade.quiz_question = question
      expect(qq_regrade.question_data).to eq "foo"
    end
  end
end
