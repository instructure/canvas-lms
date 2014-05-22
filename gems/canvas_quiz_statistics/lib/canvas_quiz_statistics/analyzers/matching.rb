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
  # Generates statistics for a set of student responses to a Fill In Multiple
  # Blanks question.
  #
  # Response object should look something like this for a matching question with
  # three answers with the ids 8796, 6666, 6430:
  #
  # ```json
  # {
  #  "correct": "partial", // can be "false", "true", or "partial"
  #  "points": 0.6666666666666666,
  #  "question_id": 21,
  #  "text": "",
  #  "answer_8796": "1525",
  #  "answer_6666": "4393",
  #  // Note: if no answer was provided, the key may or may not be present
  #  "answer_6430": ""
  # }
  # ```
  class Matching < Base
    include Base::Constants

    inherit :correct, :partially_correct, :incorrect, {
      from: :fill_in_multiple_blanks
    }

    # Number of students who have made at least one matching.
    #
    # @return [Integer]
    metric :responses => [ :answers ] do |responses, answers|
      responses.select do |response|
        answers.any? do |answer|
          answer_present?(response, answer[:id])
        end
      end.length
    end

    # Number of students who matched everything, even if incorrectly.
    #
    # @return [Integer]
    metric :answered => [ :answers ] do |responses, answers|
      responses.select do |response|
        answers.all? do |answer|
          answer_present?(response, answer[:id])
        end
      end.length
    end

    # Statistics for the answer sets (blanks).
    #
    # @return [Array<Hash>]
    #
    # Each entry in the answer set represents the left-hand side of the match
    # along with all the possible matches on the right-side.
    #
    # Example output:
    #
    # ```json
    # {
    #   "answer_sets": [
    #     {
    #       // id of the answer
    #       "id": "1",
    #       // the left-hand side of the match
    #       "text": "",
    #       // the available matches
    #       "answers": [
    #         // Students who chose this match for this answer set:
    #         {
    #           // match_id
    #           "id": "9711",
    #           // right-hand side of the match
    #           "text": "Red",
    #           "responses": 3,
    #           "correct": true
    #         },
    #         // Students who chose an incorrect match:
    #         {
    #           "id": "2700",
    #           "text": "Blue",
    #           "responses": 0,
    #           "correct": false
    #         },
    #         // Students who did not make any match:
    #         {
    #           "id": "none",
    #           "text": "No Answer",
    #           "responses": 1,
    #           "correct": false
    #         }
    #       ]
    #     }
    #   ]
    # }
    metric :answer_sets => [ :answers, :matches ] do |responses, answers, matches|
      answer_sets = answers.map do |answer|
        {
          id: answer[:id].to_s,
          text: answer[:text].to_s,
          responses: 0,
          answers: matches.map do |match|
            build_answer(match[:match_id],
              match[:text],
              answer[:match_id].to_s == match[:match_id].to_s)
          end
        }
      end

      answer_sets.each do |set|
        responses.each do |response|
          match_id = response[answer_key(set[:id])].to_s
          match = set[:answers].detect { |a| a[:id] == match_id }
          match ||= generate_missing_answer(set)

          match[:responses] += 1
        end
      end
    end

    private

    def answer_ids
      @answer_ids ||= question_data[:answers].map { |a| a[:id].to_s }
    end

    def match_ids
      @match_ids ||= question_data[:matches].map { |a| a[:match_id].to_s }
    end

    def build_context(responses)
      {}.tap do |ctx|
        ctx[:answers] = question_data[:answers]
        ctx[:matches] = question_data[:matches]
        ctx[:grades] = responses.map { |r| r.fetch(:correct, nil) }.map(&:to_s)
      end
    end

    def answer_key(id)
      "answer_#{id}".to_sym
    end

    def answer_present?(response, id)
      match_id = response[answer_key(id)].to_s
      answer_ids.include?(id.to_s) && match_ids.include?(match_id)
    end

    def build_answer(id, text, correct=false)
      {
        id: "#{id}",
        text: text.to_s,
        correct: correct,
        responses: 0
      }
    end

    def generate_missing_answer(answer_set)
      answer = answer_set[:answers].detect { |a| a[:id] == MissingAnswerKey }

      unless answer.present?
        answer = build_answer(MissingAnswerKey, MissingAnswerText)
        answer_set[:answers] << answer
      end

      answer
    end
  end
end
