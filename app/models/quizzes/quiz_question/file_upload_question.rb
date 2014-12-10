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

class Quizzes::QuizQuestion::FileUploadQuestion < Quizzes::QuizQuestion::Base

  def requires_manual_scoring?(user_answer)
    true
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    stats = {:file_upload_responses => []}

    responses.each do |response|
      stats[:file_upload_responses] << {
        # TODO: what does file upload quiz stats need?
        :user_id => response[:user_id]
        # :filename => response[:text].strip
      }
    end

    @question_data.merge stats
  end


  def score_question(answer_data)
    user_answer = Quizzes::QuizQuestion::FileUploadAnswer.new(self.question_id,
                                                     self.points_possible,
                                                     answer_data)
    super(answer_data, user_answer)
  end

end
