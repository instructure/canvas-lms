#
# Copyright (C) 2011 - present Instructure, Inc.
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
module Api::V1::QuizzesNext::Quiz
  extend Api::V1::Quiz

  def quizzes_next_json(quizzes, context, user, session, options={})
    quizzes.map do |quiz|
      quiz_json(quiz, context, user, session, options, klass(quiz))
    end
  end

  private

  def klass(quiz)
    return ::QuizzesNext::QuizSerializer if quiz.is_a?(Assignment)

    return Quizzes::QuizSerializer if quiz.is_a?(Quizzes::Quiz)

    raise ArgumentError, 'An invalid quiz object is passed to quizzes_next_json'
  end
end
