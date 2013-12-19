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

module QuizQuestion::AnswerParsers
  class MultipleChoice < AnswerParser
    def parse(question)
      @answers.map_with_group! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)

        id = fields.fetch(:id, nil)
        id = id.to_i if id
        text = fields.fetch_with_enforced_length(:answer_text)
        comments = fields.fetch_with_enforced_length(:answer_comments)
        weight = fields.fetch(:answer_weight).to_f
        html = fields.sanitize(fields.fetch(:answer_html))

        answer = QuizQuestion::AnswerGroup::Answer.new(id: id, text: text, html: html, comments: comments, weight: weight)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end
      @answers.set_correct_if_none

      question.answers = @answers
      question
    end
  end
end

