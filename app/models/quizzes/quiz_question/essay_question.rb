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

class Quizzes::QuizQuestion::EssayQuestion < Quizzes::QuizQuestion::Base
  def requires_manual_scoring?(user_answer)
    true
  end

  def correct_answer_parts(user_answer)
    config = CanvasSanitize::SANITIZE
    user_answer.answer_details[:text] = Sanitize.clean(user_answer.answer_text, config) || ""
    nil
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    stats = {:essay_responses => []}

    responses.each do |response|
      stats[:essay_responses] << {
        :user_id => response[:user_id],
        :text => response[:text].to_s.strip
      }
    end

    @question_data.merge stats
  end
end
