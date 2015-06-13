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
  class Matching < AnswerParser
    def parse(question)
      question[:matches] = []

      match_ids = {}
      @answers.map_with_group! do |answer_group, answer|
        fields = Quizzes::QuizQuestion::RawFields.new(answer)
        a = {
          id: fields.fetch_any(:id, nil),
          text: fields.fetch_with_enforced_length(:answer_match_left),
          left: fields.fetch_with_enforced_length(:answer_match_left),
          right: fields.fetch_with_enforced_length(:answer_match_right),
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          comments_html: fields.fetch_with_enforced_length([:answer_comment_html, :comments_html])
        }

        a[:left_html] = a[:html] = fields.sanitize(fields.fetch_any(:answer_match_left_html)) if answer[:answer_match_left_html].present?

        a[:match_id] = answer[:match_id].to_i

        answer = Quizzes::QuizQuestion::AnswerGroup::Answer.new(a)

        # duplicate text in options need the same match_id
        right_text = a[:right]
        if match_ids[right_text]
          answer[:match_id] =  match_ids[right_text]
        else
          match_ids[right_text] = answer.set_id(answer_group.taken_ids, :match_id)
          answer_group.taken_ids << match_ids[right_text]
        end
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)

        question[:matches] << {match_id: a[:match_id], text: a[:right]}

        answer
      end
      question[:matching_answer_incorrect_matches].split("\n").each do |other|
        fields = Quizzes::QuizQuestion::RawFields.new({distractor: other[0..255]})
        question.match_group.add(text: fields.fetch_with_enforced_length(:distractor))
      end

      question[:matches] = question.match_group.to_a
      question.answers = @answers

      question
    end

  end
end
