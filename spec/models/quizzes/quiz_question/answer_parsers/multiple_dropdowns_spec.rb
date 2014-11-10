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

describe Quizzes::QuizQuestion::AnswerParsers::MultipleDropdowns do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  context "#parse" do
    let(:raw_answers) do
      [
        {
          answer_text: "Answer 1",
          answer_comments: "This is answer 1",
          answer_weight: 0,
          text_after_answers: "Text after Answer 1",
          id: '1000'

        },
        {
          answer_text: "Answer 2",
          answer_comments: "This is answer 2",
          answer_weight: 100,
          text_after_answers: "Text after Answer 2",
          id: 1001
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
    let(:parser_class) { Quizzes::QuizQuestion::AnswerParsers::MultipleDropdowns }

    include_examples "All answer parsers"

  end
end
