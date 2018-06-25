#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'bigdecimal'

module Qti
class NumericInteraction < AssessmentItemConverter
  def initialize(opts={})
    super(opts)
    @question[:question_type] = 'numerical_question'
    @type = opts[:custom_type]
  end

  def parse_question_data
    get_answer_values()
    get_canvas_answers
    attach_feedback_values(@question[:answers])
    get_feedback()
    @question
  end

  def get_answer_values
    answer = {:weight=>100,:comments=>"",:id=>unique_local_id}
    if gte = @doc.at_css('responseCondition gte baseValue')
      answer[:start] = gte.text.to_f
    end
    if lte = @doc.at_css('responseCondition lte baseValue')
      answer[:end] = lte.text.to_f
    end

    if (answer[:start] && answer[:end])
      answer[:numerical_answer_type] = "range_answer"
      @question[:answers] << answer
    elsif equal = @doc.at_css('responseCondition equal baseValue')
      answer[:exact] = equal.text.to_f
      answer[:numerical_answer_type] = "exact_answer"
      @question[:answers] << answer
    end
  end

  def get_canvas_answers
    @doc.css('responseIf, responseElseIf').each do |r_if|
      answer = {:weight=>100, :id=>unique_local_id, :text=>'answer_text'}
      answer[:feedback_id] = get_feedback_id(r_if)

      if or_node = r_if.at_css('or')
        # exact answer
        exact_node = or_node.at_css('stringMatch baseValue')
        next unless exact_node
        exact = exact_node.text rescue "0.0"

        is_precision = false
        if (lower_node = or_node.at_css('and customOperator[class=vargt] baseValue')) &&
            (upper_node = or_node.at_css('and customOperator[class=varlte] baseValue')) &&
            lower_node.text.gsub(/[0\.]/, "").end_with?("5") && upper_node.text.gsub(/[0\.]/, "").end_with?("5")
          # tl;dr - super hacky way to try to detect the precision answers
          upper = upper_node.text.to_d
          lower = lower_node.text.to_d
          exact_num = exact.to_d

          if (exact_num - lower) == (upper - exact_num) # same margin on each side
            _, sig_digits, _b, exp = (upper - lower).split
            if sig_digits == "1" # i.e. is a power of 10
              is_precision = true
              answer[:precision] = exact_num.exponent - exp + 1
              answer[:approximate] = exact_num.to_f
              answer[:numerical_answer_type] = 'precision_answer'
            end
          end
        end

        unless is_precision
          answer[:numerical_answer_type] = 'exact_answer'
          answer[:exact] = exact.to_f
          if upper = or_node.at_css('and customOperator[class=varlte] baseValue')
            # do margin computation with BigDecimal to avoid rounding errors
            # (this is also used when _scoring_ numeric range questions)
            margin = BigDecimal.new(upper.text) - BigDecimal.new(exact) rescue "0.0"
            answer[:margin] = margin.to_f
          end
        end
        @question[:answers] << answer
      elsif and_node = r_if.at_css('and')
        # range answer
        answer[:numerical_answer_type] = 'range_answer'
        if lower = and_node.at_css('customOperator[class=vargte] baseValue')
          answer[:start] = lower.text.to_f rescue 0.0
        end
        if upper = and_node.at_css('customOperator[class=varlte] baseValue')
          answer[:end] = upper.text.to_f rescue 0.0
        end
        if upper || lower
          @question[:answers] << answer
        end
      end
    end
  end

end
end
