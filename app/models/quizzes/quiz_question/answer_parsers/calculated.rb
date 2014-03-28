#
# Copyright (C) 2013 Instructure, Inc.
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

module Quizzes::QuizQuestion::AnswerParsers
  class Calculated < AnswerParser
    def parse(question)
      question[:formulas] = format_formulas(question[:formulas])
      question[:variables] = format_variables(question[:variables])

      @answers.map_with_group! do |answer_group, answer|
        answer_params = {:weight => 100, :variables => []}
        answer_params[:answer] = answer[:answer_text].to_f

        variables = hash_to_array(answer[:variables])
        variables.each do |variable|
          variable = Quizzes::QuizQuestion::RawFields.new(variable)
          answer_params[:variables] << {
            :name => variable.fetch_with_enforced_length(:name),
            :value => variable.fetch_any(:value).to_f
          }
        end

        answer = Quizzes::QuizQuestion::AnswerGroup::Answer.new(answer_params)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end

    private
    def format_formulas(formulas)
      formulas = hash_to_array(formulas)
      formulas.map do |formula|
        formula = Quizzes::QuizQuestion::RawFields.new({formula: trim_length(formula)})
        {formula: formula.fetch_with_enforced_length(:formula)}
      end
    end

    def format_variables(variables)
      hash_to_array(variables).map do |variable|
        variable = Quizzes::QuizQuestion::RawFields.new(variable.merge({name: trim_length(variable[:name])}))
        {
          name: variable.fetch_with_enforced_length(:name),
          min: variable.fetch_any(:min).to_f,
          max: variable.fetch_any(:max).to_f,
          scale: variable.fetch_any(:scale).to_i
        }
      end
    end

    def trim_length(field)
      field[0..1024]
    end

    def hash_to_array(obj)
      if obj.respond_to?(:values)
        obj.values
      else
        obj || []
      end
    end

    def trim_padding(n)
      n.to_s[9..-1].to_i
    end

  end
end
