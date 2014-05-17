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
  # Response object should look something like this for a FIMB question with
  # two blanks, "color1" and "color2:
  #
  # ```json
  # {
  #   "correct": "partial",
  #   "points": 0.5,
  #   "question_id": 46,
  #   "text": "",
  #   // the following fields may or may not be present:
  #   "answer_for_color1": "red",
  #   "answer_id_for_color1": "9711",
  #   "answer_for_color2": "purple",
  #   "answer_id_for_color2": null
  # }
  # ```
  class FillInMultipleBlanks < Base
    UnknownAnswerKey = 'other'
    UnknownAnswerText = 'Other'
    MissingAnswerKey = 'none'
    MissingAnswerText = 'No Answer'
    FalseLike = [ 'nil', 'null', 'false', '' ]

    # Number of students who have filled at least one blank.
    #
    # @return [Integer]
    metric :responses do |responses|
      responses.select { |r| answer_present?(r) }.length
    end

    # Number of students who have filled every blank.
    #
    # @return [Integer]
    metric :answered do |responses|
      responses.select { |r| answer_present?(r, true) }.length
    end

    # Number of students who filled all blanks correctly.
    #
    # @return [Integer]
    metric :correct => [ :grades ] do |responses, grades|
      grades.select { |r| r == 'true' }.length
    end

    # Number of students who filled one or more blanks correctly.
    #
    # @return [Integer]
    metric :partially_correct => [ :grades ] do |responses, grades|
      grades.select { |r| r == 'partial' }.length
    end

    # Number of students who didn't fill any blank correctly.
    #
    # @return [Integer]
    metric :incorrect => [ :grades ] do |responses, grades|
      grades.select { |r| FalseLike.include?(r) }.length
    end

    # Statistics for the answer sets (blanks).
    #
    # Each entry in the answer set represents a blank and responses to its
    # pre-defined answers:
    #
    # @return [Array<Hash>]
    #
    # Example output:
    #
    # ```json
    # {
    #   "answer_sets": [
    #     {
    #       "id": "70dda5dfb8053dc6d1c492574bce9bfd", // md5sum of the blank
    #       "text": "color", // the blank_id
    #       "answers": [
    #         // Students who filled in this blank with this correct answer:
    #         {
    #           "id": "9711",
    #           "text": "Red",
    #           "responses": 3,
    #           "correct": true
    #         },
    #         // Students who filled in this blank with this other correct answer:
    #         {
    #           "id": "2700",
    #           "text": "Blue",
    #           "responses": 0,
    #           "correct": true
    #         },
    #         // Students who filled in this blank with something else:
    #         {
    #           "id": "other",
    #           "text": "Other",
    #           "responses": 1,
    #           "correct": false
    #         },
    #         // Students who left this blank empty:
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
    metric :answer_sets => [ :blanks ] do |responses, blanks|
      build_answer_sets(blanks).tap do |sets|
        calculate_answer_responses(responses, blanks, sets)
      end
    end

    private

    def build_context(responses)
      {}.tap do |ctx|
        ctx[:grades] = responses.map { |r| r.fetch(:correct, nil) }.map(&:to_s)
        ctx[:blanks] = question_blanks
      end
    end

    def answer_present?(response, answered_all_blanks=false)
      !question_blanks.send(answered_all_blanks ? 'any?' : 'all?') do |blank|
        answer_id = response[answer_key(blank, true)]
        answer_text = response[answer_key(blank, false)]

        answer_id.blank? && answer_text.blank?
      end
    end

    def question_blanks
      @question_data[:answers].map { |a| a[:blank_id] }.uniq
    end

    def build_answer_sets(blanks)
      blanks.map do |blank|
        answers_for_blank = @question_data[:answers].select do |answer|
          answer[:blank_id] == blank
        end

        answers = answers_for_blank.map do |answer|
          build_answer(answer[:id], answer[:text], answer[:weight] == 100)
        end

        {
          id: CanvasQuizStatistics::Util.digest(blank),
          text: blank,
          answers: answers
        }
      end
    end

    def build_answer(id, text, correct=false)
      {
        id: "#{id}",
        text: text.to_s,
        correct: correct,
        responses: 0
      }
    end

    def calculate_answer_responses(responses, blanks, answer_sets)
      blanks.each do |blank|
        answer_set = answer_sets.detect { |set| set[:text] == blank }

        responses.each do |response|
          analyze_response_for_blank(response, blank, answer_set)
        end
      end
    end

    def analyze_response_for_blank(response, blank, answer_set)
      answer_id = response.fetch(answer_key(blank), nil).to_s
      answer_text = response.fetch(answer_key(blank, false), nil)

      answer = if answer_id.present?
        answer_set[:answers].detect { |a| "#{a[:id]}" == answer_id }
      elsif answer_text.present?
        generate_incorrect_answer({
          id: UnknownAnswerKey,
          text: UnknownAnswerText,
          in: answer_set
        })
      else
        generate_incorrect_answer({
          id: MissingAnswerKey,
          text: MissingAnswerText,
          in: answer_set
        })
      end

      answer[:responses] += 1
    end

    # The key to use to lookup the response in the input submission_data fragment
    #
    # The key will be "answer_id_for_blank" or "answer_for_blank" based on
    # @resolved, use the former if you're looking for a resolved answer (a
    # correct one that maps to an ID), and the second to query the text they
    # wrote.
    def answer_key(blank, resolved=true)
      [
        'answer',
        resolved ? 'id' : nil,
        'for',
        blank
      ].compact.join('_').to_sym
    end

    def generate_incorrect_answer(props)
      id, text, answer_set = *[ props[:id], props[:text], props[:in] ]

      answer = answer_set[:answers].detect { |a| a[:id] == id }

      unless answer.present?
        answer = build_answer(id, text)
        answer_set[:answers] << answer
      end

      answer
    end
  end
end
