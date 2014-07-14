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
  require 'canvas_quiz_statistics/analyzers/fill_in_multiple_blanks'

  # Generates statistics for a set of student responses to a multiple-answers
  # question.
  #
  # Response is expected to look something like this:
  #
  # ```javascript
  # {
  #   "correct": "partial",
  #   "points": 0.5,
  #   "question_id": 17,
  #   "text": "",
  #   "answer_5514": "1",
  #   "answer_4261": "0",
  #   "answer_3322": "1"
  # }
  # ```
  class MultipleAnswers < Base
    include Concerns::HasAnswers

    # Number of students who have answered this question by picking any choice.
    #
    # @return [Integer]
    metric :responses do |responses|
      responses.select(&method(:answer_present?)).length
    end

    inherit :correct, :partially_correct, from: :fill_in_multiple_blanks

    # Statistics for the answers.
    #
    # Example output:
    #
    # ```json
    # {
    #   "answers": [
    #     // First part of the correct answer:
    #     {
    #       "id": "5514",
    #       "text": "A",
    #       "responses": 3,
    #       "correct": true
    #     },
    #     // The second part of the correct answer:
    #     {
    #       "id": "4261",
    #       "text": "B",
    #       "responses": 0,
    #       "correct": true
    #     },
    #     // A wrong choice:
    #     {
    #       "id": "3322",
    #       "text": "C",
    #       "responses": 0,
    #       "correct": false
    #     },
    #     // Students who didn't make any choice:
    #     {
    #       "id": "none",
    #       "text": "No Answer",
    #       "responses": 1,
    #       "correct": false
    #     }
    #   ]
    # }
    metric :answers do |responses|
      answers = parse_answers do |answer, answer_stats|
        answer_stats.merge!({ responses: 0 })
      end

      answers.tap { calculate_responses(responses, answers) }
    end

    private

    def build_context(responses)
      {}.tap do |ctx|
        ctx[:grades] = responses.map { |r| r.fetch(:correct, nil) }.map(&:to_s)
      end
    end

    def answer_present?(response)
      answer_ids.any? { |id| chosen?(response[answer_key(id)]) }
    end

    def answer_ids
      @answer_ids ||= question_data[:answers].map { |a| "#{a[:id]}" }
    end

    def answer_key(id)
      :"answer_#{id}"
    end

    def chosen?(value)
      value.to_s == '1'
    end

    def extract_chosen_choices(response, answers)
      answers.select do |answer|
        chosen?(response[answer_key(answer[:id])])
      end
    end

    def calculate_responses(responses, answers, *args)
      responses.each do |response|
        choices = extract_chosen_choices(response, answers, *args)

        if choices.empty?
          choices = [ generate_missing_answer(answers) ]
        end

        choices.each { |answer| answer[:responses] += 1 }
      end
    end
  end
end
