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

module Quizzes::QuizQuestion::AnswerParsers
  class Numerical < AnswerParser
    def parse(question)
      @answers.map_with_group! do |answer_group, answer|
        fields = Quizzes::QuizQuestion::RawFields.new(answer)
        a = {
          id: fields.fetch_any(:id, nil),
          text: fields.fetch_with_enforced_length([:answer_text, :text]),
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          comments_html: fields.sanitize(fields.fetch_with_enforced_length([:answer_comment_html, :comments_html])),
          weight: 100
        }

        a[:numerical_answer_type] = fields.fetch_any(:numerical_answer_type)

        if a[:numerical_answer_type] == "exact_answer"
          a[:exact] = fields.fetch_any(:answer_exact).to_f
          a[:margin] = fields.fetch_any(:answer_error_margin).to_f
        elsif a[:numerical_answer_type] == "precision_answer"
          a[:approximate] = fields.fetch_any(:answer_approximate).to_f
          a[:precision] = fields.fetch_any(:answer_precision).to_i
        else
          a[:numerical_answer_type] = "range_answer"
          a[:start] = fields.fetch_any(:answer_range_start).to_f
          a[:end] = fields.fetch_any(:answer_range_end).to_f
        end

        answer = Quizzes::QuizQuestion::AnswerGroup::Answer.new(a)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end
  end
end
