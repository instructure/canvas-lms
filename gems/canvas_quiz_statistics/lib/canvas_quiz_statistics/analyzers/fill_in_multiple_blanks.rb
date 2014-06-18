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
    include Concerns::HasAnswers

    # Number of students who have filled at least one blank.
    #
    # @return [Integer]
    metric :responses => [ :blanks ] do |responses, blanks|
      responses.select do |response|
        blanks.any? do |blank|
          answer_present_for_blank?(response, blank)
        end
      end.length
    end

    # Number of students who have filled every blank.
    #
    # @return [Integer]
    metric :answered do |responses|
      responses.select { |r| answer_present?(r) }.length
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
      grades.select { |r| Base::Constants::FalseLike.include?(r) }.length
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
      answer_sets = blanks.map do |blank|
        answers_for_blank = @question_data[:answers].select do |answer|
          answer[:blank_id] == blank
        end

        {
          id: CanvasQuizStatistics::Util.digest(blank),
          text: blank,
          answers: parse_answers(answers_for_blank)
        }
      end

      blanks.each do |blank|
        answer_sets.detect { |set| set[:text] == blank }.tap do |answer_set|
          calculate_responses(responses, answer_set[:answers], blank)
        end
      end

      answer_sets
    end

    private

    def question_blanks
      @question_data[:answers].map { |a| a[:blank_id] }.uniq
    end

    def build_context(responses)
      {}.tap do |ctx|
        ctx[:grades] = responses.map { |r| r.fetch(:correct, nil) }.map(&:to_s)
        ctx[:blanks] = question_blanks
      end
    end

    def answer_present?(response)
      question_blanks.all? { |blank| answer_present_for_blank?(response, blank) }
    end

    def answer_present_for_blank?(response, blank)
      response[key_for_answer_id(blank)].present? ||
      response[key_for_answer_text(blank)].present?
    end

    def locate_answer(response, answers, blank)
      answer_id = response[key_for_answer_id(blank)].to_s
      answers.detect { |answer| answer[:id] == answer_id }
    end

    def answer_present_but_unknown?(response, blank)
      response[key_for_answer_text(blank)].present?
    end

    # The key to use to lookup the _resolved_ answer ID.
    def key_for_answer_id(blank)
      :"answer_id_for_#{blank}"
    end

    # The key to use to lookup the text the student wrote.
    def key_for_answer_text(blank)
      :"answer_for_#{blank}"
    end
  end
end
