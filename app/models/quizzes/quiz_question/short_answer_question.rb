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

class Quizzes::QuizQuestion::ShortAnswerQuestion < Quizzes::QuizQuestion::Base
  def correct_answer_parts(user_answer)
    answer = matching_answer(user_answer)
    # if nil answer (question not presented to student... undefined). return nil directly
    return nil if answer.nil?

    if answer
      user_answer.answer_id = answer[:id]
    end

    !!answer
  end

  # Find and return the matching answer for the user's answer.
  # If no matching answer is found, a +nil+ is returned.
  def matching_answer(user_answer)
    answer_text = user_answer.answer_text
    return nil if answer_text.nil?

    answer_text = CGI::escapeHTML(answer_text).strip.downcase

    answer = @question_data[:answers].sort_by { |a| a[:weight] || CanvasSort::First }.find do |answer|
      valid_answer = (answer[:text] || '').strip.downcase
      # Ignore blank answers (no match on that)
      (CGI::escapeHTML(valid_answer) == answer_text) && !valid_answer.blank?
    end
    answer
  end

end
