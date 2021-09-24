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
  class Essay < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer

    # @param answer_html [String]
    #   The textual/HTML answer. Will be HTML escaped.
    #
    # @example output for an answer for QuizQuestion#1
    #  {
    #    :question_1 => "&lt;p&gt;Hello World!&lt;/p&gt;"
    #  }
    def serialize(answer_html)
      rc = SerializedAnswer.new

      unless answer_html.is_a?(String)
        return rc.reject :invalid_type, 'answer', String
      end

      answer_html = Util.sanitize_html answer_html

      if Util.text_too_long?(answer_html)
        return rc.reject :text_too_long
      end

      rc.answer[question_key] = answer_html
      rc
    end

    # @return [String|NilClass]
    #   The HTML-escaped textual answer, or nil if no response was received.
    def deserialize(submission_data, full=false)
      text = submission_data[question_key]

      if text.present?
        text
      end
    end
  end
end
