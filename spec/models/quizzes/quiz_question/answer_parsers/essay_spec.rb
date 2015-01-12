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

describe Quizzes::QuizQuestion::AnswerParsers::Essay do

  describe "#parse" do
    let(:raw_answers) do
      [
        {
          answer_text: "Essay Answer",
          answer_comments: "This is an essay answer"
        }
      ]
    end

    let(:parser_class) { Quizzes::QuizQuestion::AnswerParsers::Essay }
    let(:question_params) { Hash.new }

    it "seeds a question with comments" do
      essay = Quizzes::QuizQuestion::AnswerParsers::Essay.new(raw_answers)
      question = Quizzes::QuizQuestion::QuestionData.new({})
      essay.parse(question)
      expect(question[:comments]).to eq raw_answers[0][:answer_comments]
    end
  end
end
