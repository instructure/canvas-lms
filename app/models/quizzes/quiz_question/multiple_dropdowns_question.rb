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

class Quizzes::QuizQuestion::MultipleDropdownsQuestion < Quizzes::QuizQuestion::FillInMultipleBlanksQuestion
  def find_chosen_answer(variable, response)
    @question_data.answers.detect { |answer| answer[:blank_id] == variable && answer[:id].to_i == response.to_i } || {:text => nil, :id => nil, :weight => 0}
  end

  def answer_text(answer)
    answer[:id]
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    @question_data = super
    answers = @question_data[:answer_sets]

    responses.each do |response|
      answers.each do |answer|
        answer[:responses] += 1 if response[:correct]
        answer[:answer_matches].each do |right|
          if response[:"answer_id_for_#{answer[:blank_id]}"] == right[:id]
            right[:responses] += 1
            right[:user_ids] << response[:user_id]
          end
        end
      end
    end

    @question_data
  end
end
