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
  class MultipleDropdowns < FillInMultipleBlanks
    protected

    # Rejects if the answer id is bad or doesn't identify a known answer
    def validate_blank_answer(blank, answer_id, rc)
      answer_id = Util.to_integer answer_id

      if answer_id.nil?
        rc.reject :invalid_type, "answer.#{blank}", Integer
      elsif !answer_available? answer_id
        rc.reject :unknown_answer, answer_id
      end
    end

    def serialize_blank_answer(answer_id)
      answer_id.to_i.to_s
    end

    def deserialize_blank_answer(answer_id)
      answer_id
    end
  end
end
