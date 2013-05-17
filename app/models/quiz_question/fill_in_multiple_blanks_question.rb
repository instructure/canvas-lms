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

class QuizQuestion::FillInMultipleBlanksQuestion < QuizQuestion::Base
  def total_answer_parts
    variables.length
  end

  def variables
    @variables ||= @question_data[:answers].map{|a| a[:blank_id] }.uniq
  end

  def find_chosen_answer(variable, response)
    response = (response || "").strip.downcase
    @question_data[:answers].detect{|answer| answer[:blank_id] == variable && (answer[:text] || "").strip.downcase == response } || { :text => response, :id => nil, :weight => 0 }
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

    return chosen_answers.count do |variable, answer|
      answer ||= { :id => nil, :text => nil, :weight => 0 }
      user_answer.answer_details["answer_for_#{variable}".to_sym] = answer_text(answer)
      user_answer.answer_details["answer_id_for_#{variable}".to_sym] = answer[:id]
      answer && answer[:weight] == 100 && !variables.empty?
    end
  end

  def stats(responses)
    stats = {:multiple_responses => true}

    answer_keys = {}
    answers = []
    @question_data[:answers].each do |answer|
      unless answer_keys[answer[:blank_id]]
        answers << {
          :id => answer[:blank_id],
          :text => answer[:blank_id],
          :blank_id => answer[:blank_id],
          :answer_matches => [],
          :responses => 0,
          :user_ids => []
        }
        answer_keys[answer[:blank_id]] = answers.length - 1
      end
    end
    answers.each do |found_answer|
      @question_data[:answers].select { |a|
        a[:blank_id] == found_answer[:blank_id]
      }.each do |sub_answer|
        correct = sub_answer[:weight] == 100
        match = {
          :responses => 0,
          :text => sub_answer[:text],
          :user_ids => [],
          :id => @question_data[:question_type] == 'fill_in_multiple_blanks_question' ? found_answer[:blank_id] : sub_answer[:id],
          :correct => correct
        }
        found_answer[:answer_matches] << match
      end
    end
    stats[:answer_sets] = answers

    if @question_data[:question_type] == 'fill_in_multiple_blanks_question'
      responses.each do |response|
        answers.each do |answer|
          found = false
          if (txt = response[:"answer_for_#{answer[:blank_id]}"].try(:strip)).present?
            answer_md5 = Digest::MD5.hexdigest(txt)
          end
          answer[:responses] += 1 if response[:correct]
          answer[:answer_matches].each do |right|
            if response["answer_for_#{answer[:blank_id]}".to_sym] == right[:text]
              found = true
              right[:responses] += 1
              right[:user_ids] << response[:user_id]
            end
          end
          if !found
            if answer_md5
              match = {
                :id => answer_md5,
                :responses => 1,
                :user_ids => [response[:user_id]],
                :text => response["answer_for_#{answer[:blank_id]}".to_sym]
              }
              answer[:answer_matches] << match
            end
          end
        end
      end
    end

    @question_data.merge stats
  end
end
