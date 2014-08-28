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
  require 'canvas_quiz_statistics/analyzers/multiple_choice'
  require 'canvas_quiz_statistics/analyzers/fill_in_multiple_blanks'

  # Generates statistics for a set of student responses to a short answer,
  # aka Fill in the Blank, question.
  #
  # Response is expected to look something like this:
  #
  # ```javascript
  # {
  #   "correct": true,
  #   "points": 1,
  #   "question_id": 15,
  #   "answer_id": 4684,
  #   "text": "Something"
  # }
  # ```
  #
  class ShortAnswer < MultipleChoice
    include Concerns::HasAnswers

    inherit :all, from: :multiple_choice
    inherit :correct, from: :fill_in_multiple_blanks

    private

    def build_context(responses)
      {}.tap do |ctx|
        ctx[:grades] = responses.map { |r| r.fetch(:correct, nil) }.map(&:to_s)
      end
    end

    # this question type supports "free-form" input so we do want to generate
    # the UnknownAnswer
    def answer_present_but_unknown?(response)
      answer_present?(response)
    end

    # true if any text was written, or a known answer_id is provided
    def answer_present?(response)
      response[:text].present? ||
      locate_answer(response, question_data[:answers]).present?
    end
  end
end
