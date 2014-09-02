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
  require 'canvas_quiz_statistics/analyzers/essay'

  # Generates statistics for a set of student responses to a multiple-choice
  # question.
  #
  # Response is expected to look something like this:
  #
  # ```javascript
  # {
  #   "correct": true,
  #   "points": 1,
  #   "question_id": 43,
  #   "answer_id": 3023,
  #   "text": "3023"
  # }
  # ```
  #
  class MultipleChoice < Base
    include Concerns::HasAnswers

    inherit :responses, from: :essay

    # Statistics for the pre-defined answers.
    #
    # @return [Array<Hash>]
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
    #       // The readable answer text.
    #       "text": "Red",
    #
    #       // Number of students who picked this answer.
    #       "responses": 3,
    #
    #       // Whether this answer is a correct one.
    #       "correct": true
    #     }
    #   ]
    # }
    metric :answers do |responses|
      answers = parse_answers do |answer, answer_stats|
        stats = {
          responses: 0
        }

        if answer[:text].blank? && answer[:html].present?
          stats[:text] = CanvasQuizStatistics::Util.strip_tags(answer[:html])
        end

        answer_stats.merge!(stats)
      end

      answers.tap { calculate_responses(responses, answers) }
    end

    private

    # Can't have the UnknownAnswer for this question type since students only
    # get to pick one of the pre-defined choices.
    def answer_present_but_unknown?(*args)
      false
    end

    def locate_answer(response, answers, *args)
      answers.detect { |a| "#{a[:id]}" == "#{response[:answer_id]}" }
    end

    def answer_present?(response)
      locate_answer(response, question_data[:answers]).present?
    end
  end
end
