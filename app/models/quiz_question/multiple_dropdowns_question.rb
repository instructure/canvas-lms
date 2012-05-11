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

class QuizQuestion::MultipleDropdownsQuestion < QuizQuestion::FillInMultipleBlanksQuestion
  def find_chosen_answer(variable, response)
    @question_data[:answers].detect{ |answer| answer[:blank_id] == variable && answer[:id] == response.to_i } || { :text => nil, :id => nil, :weight => 0 }
  end

  def answer_text(answer)
    answer[:id]
  end
end
