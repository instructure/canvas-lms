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

class QuizQuestion::MatchingQuestion < QuizQuestion::Base
  def total_answer_parts
    @question_data[:answers].length
  end

  def correct_answer_parts(user_answer)
    total_answers = 0
    correct_answers = 0

    @question_data[:answers].each do |answer|
      answer_match = user_answer["answer_#{answer[:id]}"].to_s

      if answer_match.present?
        total_answers += 1
        found_matched = @question_data[:answers].find {|a| a[:match_id].to_i == answer_match.to_i }
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
end
