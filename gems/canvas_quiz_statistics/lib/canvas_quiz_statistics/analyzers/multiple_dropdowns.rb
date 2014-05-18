#
# Copyright (C) 2014 Instructure, Inc.
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
module CanvasQuizStatistics::Analyzers
  class MultipleDropdowns < FillInMultipleBlanks
    inherit_metrics :fill_in_multiple_blanks_question

    private

    def analyze_response_for_blank(response, blank, answer_set)
      answer_id = response.fetch(answer_key(blank), nil).to_s

      answer = if answer_id.present?
        answer_set[:answers].detect { |a| "#{a[:id]}" == answer_id }
      end

      answer ||= generate_incorrect_answer({
        id: MissingAnswerKey,
        text: MissingAnswerText,
        in: answer_set
      })

      answer[:responses] += 1 if answer.present?
    end
  end
end
