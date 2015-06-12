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
  class Essay < AnswerParser
    def parse(question)
      comment = @answers.empty? ? "" : Quizzes::QuizQuestion::AnswerGroup::Answer.new(@answers.first).any_value_of([:answer_comments, :comments])
      comments_html = @answers.empty? ? "" : Quizzes::QuizQuestion::AnswerGroup::Answer.new(@answers.first).any_value_of([:answer_comment_html, :comments_html])

      answer = Quizzes::QuizQuestion::RawFields.new({comments: comment, comments_html: comments_html})
      question[:comments] = answer.fetch_with_enforced_length(:comments, max_size: 5.kilobyte)
      question[:comments_html] = answer.fetch_with_enforced_length(:comments_html, max_size: 5.kilobyte)

      question.answers = @answers
      question
    end
  end
end
