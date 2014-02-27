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

module Quizzes::QuizQuestion::AnswerParsers
  class FillInMultipleBlanks < AnswerParser
    def parse(question)
      @answers.map_with_group! do |answer_group, answer|
        fields = Quizzes::QuizQuestion::RawFields.new(answer)

        answer = Quizzes::QuizQuestion::AnswerGroup::Answer.new({
          id: fields.fetch_any(:id, nil),
          text: fields.fetch_with_enforced_length([:answer_text, :text]),
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          weight: fields.fetch_any([:answer_weight, :weight]).to_f,
          blank_id: fields.fetch_with_enforced_length(:blank_id)
        })

        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end
  end
end
