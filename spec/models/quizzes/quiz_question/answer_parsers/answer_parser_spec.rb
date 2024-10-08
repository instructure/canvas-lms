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

require "ostruct"

describe Quizzes::QuizQuestion::AnswerParsers::AnswerParser do
  describe "#parse" do
    let(:answer_parser) { Quizzes::QuizQuestion::AnswerParsers::AnswerParser.new([]) }

    it "returns the question with answers assigned" do
      question = Quizzes::QuizQuestion::AnswerGroup.new
      expect(answer_parser.parse(question).answers).to eq []
    end
  end
end
