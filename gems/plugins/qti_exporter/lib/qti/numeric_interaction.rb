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
    answer = {:weight=>100,:comments=>"",:id=>unique_local_id,:numerical_answer_type=>"range_answer"}
    if gte = @doc.at_css('responseCondition gte baseValue')
      answer[:start] = gte.text.to_f
    end
    if lte = @doc.at_css('responseCondition lte baseValue')
      answer[:end] = lte.text.to_f
    end
    if equal = @doc.at_css('responseCondition equal baseValue')
      answer[:exact] = equal.text.to_f
    end
    if (answer[:start] && answer[:end]) || answer[:exact]
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
        answer[:numerical_answer_type] = 'exact_answer'
        exact = exact_node.text rescue "0.0"
        answer[:exact] = exact.to_f
        if upper = or_node.at_css('and customOperator[class=varlte] baseValue')
          # do margin computation with BigDecimal to avoid rounding errors
          # (this is also used when _scoring_ numeric range questions)
          margin = BigDecimal.new(upper.text) - BigDecimal.new(exact) rescue "0.0"
          answer[:margin] = margin.to_f
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
