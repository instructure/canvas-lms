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

class Quizzes::QuizQuestion::MatchingQuestion < Quizzes::QuizQuestion::Base
  def total_answer_parts
    @question_data.answers.length
  end

  def correct_answer_parts(user_answer)
    total_answers = 0
    correct_answers = 0

    @question_data.answers.each do |answer|
      answer_match = user_answer["answer_#{answer[:id]}"].to_s

      if answer_match.present?
        total_answers += 1
        found_matched = @question_data.answers.find { |a| a[:match_id].to_i == answer_match.to_i }
        if found_matched == answer || (found_matched && found_matched[:right] && found_matched[:right] == answer[:right])
          correct_answers += 1
          answer_match = answer[:match_id].to_s
        end
      end

      user_answer.answer_details["answer_#{answer[:id]}".to_sym] = answer_match
    end

    return nil if total_answers == 0

    correct_answers
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    stats = {:multiple_answers => true}

    answers = @question_data.answers
    matches = @question_data[:matches]

    answers.each_with_index do |answer, i|
      answers[i][:answer_matches] = []
      (matches || answers).each do |right|
        match_answer = answers.find { |a|
          a[:match_id].to_i == right[:match_id].to_i
        }
        match = {
          :responses => 0,
          :text => (right[:right] || right[:text]),
          :user_ids => [],
          :id => match_answer ? match_answer[:id] : right[:match_id]
        }
        answers[i][:answer_matches] << match
      end
    end

    responses.each do |response|
      answers.each do |answer|
        answer[:responses] += 1 if response[:correct]
        (matches || answers).each_with_index do |right, j|
          if response[:"answer_#{answer[:id]}"].to_i == right[:match_id]
            answer[:answer_matches][j][:responses] += 1
            answer[:answer_matches][j][:user_ids] << response[:user_id]
          end
        end
      end
    end

    @question_data.merge stats
  end
end
