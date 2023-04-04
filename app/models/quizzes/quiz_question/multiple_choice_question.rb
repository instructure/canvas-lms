# frozen_string_literal: true

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

class Quizzes::QuizQuestion::MultipleChoiceQuestion < Quizzes::QuizQuestion::Base
  def correct_answer_parts(user_answer)
    answer_text = user_answer.answer_text
    return nil if answer_text.nil?

    answer_id = answer_text.to_i
    answer = @question_data.answers.find { |a| a[:id] == answer_id }

    return 0 unless answer

    user_answer.answer_id = answer[:id] || answer[:answer_id]
    (answer[:weight] == 100) ? 1 : 0
  end
end

class Quizzes::QuizQuestion::TrueFalseQuestion < Quizzes::QuizQuestion::MultipleChoiceQuestion
end

class Quizzes::QuizQuestion::MissingWordQuestion < Quizzes::QuizQuestion::MultipleChoiceQuestion
end
