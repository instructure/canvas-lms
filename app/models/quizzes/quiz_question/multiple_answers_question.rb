#
# Copyright (C) 2012 Instructure, Inc.
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

class Quizzes::QuizQuestion::MultipleAnswersQuestion < Quizzes::QuizQuestion::Base
  def total_answer_parts
    len = @question_data[:answers].select { |a| a[:weight] == 100 }.length
    len = 1 if len == 0
    len
  end

  def incorrect_answer_parts(user_answer)
    @incorrect_answers
  end

  def correct_answer_parts(user_answer)
    total_answers = 0
    correct_answers = 0
    @incorrect_answers = 0

    @question_data[:answers].each do |answer|
      response = user_answer["answer_#{answer[:id]}"]
      next unless response
      total_answers += 1
      user_answer.answer_details["answer_#{answer[:id]}".to_sym] = response

      # Total possible is divided by the number of correct answers.
      # For every correct answer they correctly select, they get partial
      # points.  For every correct answer they don't select, do nothing.
      # For every incorrect answer that they select, dock them partial
      # points.
      if answer[:weight] == 100 && response == "1"
        correct_answers += 1
      elsif answer[:weight] != 100 && response == "1"
        @incorrect_answers += 1
      end
    end
    return nil if total_answers == 0
    return correct_answers
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    answers = @question_data[:answers]

    responses.each do |response|
      answers.each do |answer|
        if response[:"answer_#{answer[:id]}"] == '1'
          answer[:responses] += 1
          answer[:user_ids] << response[:user_id]
        end
      end
    end

    @question_data
  end
end
