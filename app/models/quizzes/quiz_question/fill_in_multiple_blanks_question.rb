# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

class Quizzes::QuizQuestion::FillInMultipleBlanksQuestion < Quizzes::QuizQuestion::Base
  def total_answer_parts
    variables.length
  end

  def variables
    @variables ||= @question_data.answers.pluck(:blank_id).uniq
  end

  def matching_answer?(answer, variable, downcased_response)
    answer[:blank_id] == variable && (answer[:text] || "").strip.downcase == downcased_response
  end

  def find_chosen_answer(variable, response)
    response ||= ""
    downcased_response = response.strip.downcase
    matching_answer = @question_data.answers.detect { |answer| matching_answer?(answer, variable, downcased_response) }
    if matching_answer
      matching_answer.merge(text: response)
    else
      { text: response, id: nil, weight: 0 }
    end
  end

  def answer_text(answer)
    answer[:text]
  end

  def correct_answer_parts(user_answer)
    chosen_answers = {}
    total_answers = 0

    variables.each do |variable|
      variable_id = AssessmentQuestion.variable_id(variable)
      response = user_answer[variable_id]
      if response.present?
        total_answers += 1
      end
      chosen_answer = find_chosen_answer(variable, response)
      chosen_answers[variable] = chosen_answer
    end

    return nil if total_answers == 0

    chosen_answers.count do |variable, answer|
      answer ||= { id: nil, text: nil, weight: 0 }
      user_answer.answer_details[:"answer_for_#{variable}"] = answer_text(answer)
      user_answer.answer_details[:"answer_id_for_#{variable}"] = answer[:id]
      answer && answer[:weight] == 100 && !variables.empty?
    end
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    stats = { multiple_responses: true }

    answer_keys = {}
    answers = []
    @question_data.answers.each do |answer|
      next if answer_keys[answer[:blank_id]]

      answers << {
        id: answer[:blank_id],
        text: answer[:blank_id],
        blank_id: answer[:blank_id],
        answer_matches: [],
        responses: 0,
        user_ids: []
      }
      answer_keys[answer[:blank_id]] = answers.length - 1
    end
    answers.each do |found_answer|
      @question_data.answers.select do |a|
        a[:blank_id] == found_answer[:blank_id]
      end.each do |sub_answer|
        correct = sub_answer[:weight] == 100
        match = {
          responses: 0,
          text: sub_answer[:text],
          user_ids: [],
          id: @question_data.is_type?(:fill_in_multiple_blanks) ? found_answer[:blank_id] : sub_answer[:id],
          correct:
        }
        found_answer[:answer_matches] << match
      end
    end
    stats[:answer_sets] = answers

    if @question_data.is_type?(:fill_in_multiple_blanks)
      responses.each do |response|
        answers.each do |answer|
          found = false
          if (txt = response[:"answer_for_#{answer[:blank_id]}"].try(:strip)).present?
            answer_md5 = Digest::MD5.hexdigest(txt)
          end
          answer[:responses] += 1 if response[:correct]
          answer[:answer_matches].each do |right|
            next unless response[:"answer_for_#{answer[:blank_id]}"] == right[:text]

            found = true
            right[:responses] += 1
            right[:user_ids] << response[:user_id]
          end
          next unless !found && answer_md5

          match = {
            id: answer_md5,
            responses: 1,
            user_ids: [response[:user_id]],
            text: response[:"answer_for_#{answer[:blank_id]}"]
          }
          answer[:answer_matches] << match
        end
      end
    end

    @question_data.merge stats
  end
end
