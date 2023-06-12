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
  class MultipleDropdowns < AnswerParser
    def parse(question)
      variables = ActiveSupport::HashWithIndifferentAccess.new

      @answers.map_with_group! do |answer_group, answer|
        fields = Quizzes::QuizQuestion::RawFields.new(answer)

        a = {
          id: fields.fetch_any([:id, :answer_id], nil).try(:to_i),
          text: fields.fetch_with_enforced_length([:answer_text, :text]),
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          comments_html: fields.sanitize(fields.fetch_with_enforced_length([:answer_comment_html, :comments_html])),
          weight: fields.fetch_any(:answer_weight, 0).to_f,
          blank_id: fields.fetch_with_enforced_length(:blank_id)
        }

        answer = Quizzes::QuizQuestion::AnswerGroup::Answer.new(a)
        variables[answer[:blank_id]] ||= false
        variables[answer[:blank_id]] = true if answer.correct?

        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end
      question.answers = @answers

      variables.each do |variable, found_correct|
        next if found_correct

        question.answers.each_with_index do |answer, idx|
          if answer[:blank_id] == variable && !found_correct
            question.answers[idx][:weight] = 100
            found_correct = true
          end
        end
      end

      question
    end
  end
end
