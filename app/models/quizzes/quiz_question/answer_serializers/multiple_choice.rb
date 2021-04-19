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

module Quizzes::QuizQuestion::AnswerSerializers
  class MultipleChoice < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer

    # Select an answer from the set of available answers.
    #
    # Serialization request will be rejected if:
    #
    #   - the answer id is bad or unknown
    #
    # @example input where the answer ID is 123
    # {
    #   answer: 123
    # }
    #
    # @example output where the question ID is 5
    # {
    #   question_5_answer: "123"
    # }
    def serialize(answer_id)
      rc = SerializedAnswer.new
      answer_id = Util.to_integer answer_id

      if answer_id.nil?
        return rc.reject :invalid_type, 'answer', Integer
      elsif !answer_available? answer_id
        return rc.reject :unknown_answer, answer_id
      end

      rc.answer[question_key] = answer_id.to_s
      rc
    end

    # @return [String]
    #   ID of the selected answer.
    #
    # @example output for answer #3 selected:
    #   "3"
    def deserialize(submission_data, full=false)
      submission_data[question_key]
    end
  end
end
