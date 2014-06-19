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
  # Generates statistics for a set of student responses to a numerical question.
  #
  # Response is expected to look something like this:
  #
  # ```javascript
  # {
  #   "correct": true,
  #   "points": 1,
  #   "question_id": 10,
  #   "answer_id": 8224,
  #   "text": "-7.0000"
  # }
  # ```
  #
  class Numerical < Base
    include Concerns::HasAnswers

    inherit :responses, :full_credit, from: :essay
    inherit :correct, :incorrect, from: :fill_in_multiple_blanks

    # Statistics for the pre-defined answers.
    #
    # @return [Array<Hash>]
    #
    # Each entry could represent an "exact" answer, or a "range" answer.
    # Exact answers can have margins.
    #
    # Output synopsis:
    #
    # ```json
    # {
    #   "answers": [
    #     {
    #       // Unique ID of this answer.
    #       "id": "9711",
    #
    #       // This metric contains a formatted version of the correct answer
    #       // ready for display.
    #       "text": "15.00",
    #
    #       // Number of students who provided this answer.
    #       "responses": 3,
    #
    #       // Whether this answer is a correct one.
    #       "correct": true,
    #
    #       // Lower and upper boundaries of the answer range. This is consistent
    #       // regardless of the answer type (e.g., exact vs range).
    #       //
    #       // In the case of exact answers, the range will be the exact value
    #       // minus plus the defined margin.
    #       "value": [ 13.5, 16.5 ],
    #
    #       // Margin of error tolerance. This is always zero for range answers.
    #       "margin": 1.5
    #     },
    #
    #     // "Other" answers:
    #     //
    #     // This is an auto-generated answer that will be present if any student
    #     // provides a number for an answer that is incorrect (doesn't map to
    #     // any of the pre-defined answers.)
    #     {
    #       "id": "other",
    #       "text": "Other",
    #       "responses": 0,
    #       "correct": false
    #     },
    #
    #     // "Missing" answers:
    #     //
    #     // This is an auto-generated answer to account for all students who
    #     // left this question unanswered.
    #     {
    #       "id": "none",
    #       "text": "No Answer",
    #       "responses": 0,
    #       "correct": false
    #     }
    #   ]
    # }
    metric :answers do |responses|
      answers = parse_answers do |answer, answer_stats|
        is_range = range_answer?(answer)
        bounds = generate_answer_boundaries(answer, is_range)
        text = generate_text_for_answer(answer, is_range)

        answer_stats.merge!({
          text: text,
          value: bounds,
          responses: 0,
          margin: answer[:margin].to_f,
          is_range: is_range
        })
      end

      answers.tap { calculate_responses(responses, answers) }
    end

    private

    def build_context(responses)
      {
        grades: responses.map { |r| r.fetch(:correct, nil) }.map(&:to_s)
      }
    end

    def range_answer?(answer)
      answer[:numerical_answer_type] == 'range_answer'
    end

    # Exact answers will look like this: "15.00"
    # Range answers will look like this: "[3.00..54.12]"
    def generate_text_for_answer(answer, is_range)
      format = ->(value) { sprintf('%.2f', value) }

      if is_range
        range = [ answer[:start], answer[:end] ].map(&format).join('..')
        "[#{range}]"
      else
        value = format.call(answer[:exact])
        "#{value}"
      end
    end

    # Generates an array that represents the correct answer range.
    #
    # The range will be simulated for exact answers using the margin (if any).
    def generate_answer_boundaries(answer, is_range)
      if is_range
        # there's no margin in range answers
        [ answer[:start].to_f, answer[:end].to_f ]
      else
        margin = answer[:margin].to_f
        [ answer[:exact] - margin, answer[:exact] + margin ]
      end
    end

    def locate_answer(response, answers)
      answers.detect { |answer| answer[:id] == "#{response[:answer_id]}" }
    end
  end
end
