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

require 'bigdecimal'

class Quizzes::QuizQuestion::NumericalQuestion < Quizzes::QuizQuestion::Base
  class FlexRange
    def initialize(a, b)
      numbers = [ BigDecimal.new(a.to_s), BigDecimal.new(b.to_s) ].sort
      @range = numbers[0]..numbers[1]
    end

    def cover?(number)
      @range.cover?(number)
    end
  end

  def answers
    @question_data[:answers].sort_by { |a| a[:weight] || CanvasSort::First }
  end

  def correct_answer_parts(user_answer)
    answer_text = user_answer.answer_text
    return nil if answer_text.nil?
    return false if answer_text.blank?

    # we use BigDecimal here to avoid rounding errors at the edge of the tolerance
    # e.g. in floating point, -11.7 with margin of 0.02 isn't inclusive of the answer -11.72
    answer_number = BigDecimal.new(answer_text.to_s)

    match = answers.find do |answer|
      if answer[:numerical_answer_type] == "exact_answer"
        val = BigDecimal.new(answer[:exact].to_s)

        # calculate margin value using percentage
        if answer[:margin].to_s.ends_with?("%")
          answer[:margin] = (answer[:margin].to_f / 100.0 * val).abs
        end

        margin = BigDecimal.new(answer[:margin].to_s)
        min = val - margin
        max = val + margin
        answer_number >= min && answer_number <= max
      else
        FlexRange.new(answer[:start], answer[:end]).cover?(answer_number)
      end
    end

    if match
      user_answer.answer_id = match[:id]
    end

    !!match
  end

  # TODO: remove once new stats is on for everybody
  def stats(responses)
    super

    @question_data.answers.each do |answer|
      if answer[:numerical_answer_type] == 'exact_answer'
        answer[:text] = I18n.t('statistics.exact_answer', "%{exact_value} +/- %{margin}", :exact_value => answer[:exact], :margin => answer[:margin])
      else
        answer[:text] = I18n.t('statistics.inexact_answer', "%{lower_bound} to %{upper_bound}", :lower_bound => answer[:start], :upper_bound => answer[:end])
      end
    end

    @question_data
  end
end
