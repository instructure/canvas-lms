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
  class Numerical < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    # Serialize a decimal answer.
    #
    # @param [BigDecimal|String] answer
    #
    # @note
    #   This serializer does not reject any input but instead coerces everything
    #   to a BigDecimal, even if the input is not a number.
    #
    # @example acceptable inputs
    #  { answer: 1 }
    #  { answer: 2.3e-6 }
    #  { answer: "8.4" }
    #
    # @example outputs, respectively from above
    #  { question_5: 1 }
    #  { question_5: 2.3e-6 }
    #  { question_5: 8.4 }
    def serialize(answer)
      rc = SerializedAnswer.new
      # If the answer is a String we assume it is localized
      decimal_answer = answer.is_a?(String) ? Util.i18n_to_decimal(answer) : Util.to_decimal(answer)
      rc.answer[question_key] = decimal_answer
      rc
    end

    # @param String
    # @return [BigDecimal|NilClass]
    def deserialize(submission_data, full=false)
      answer = submission_data[question_key]
      if answer.present?
        answer.is_a?(String) ? Util.i18n_to_decimal(answer) : answer
      end
    end
  end
end
