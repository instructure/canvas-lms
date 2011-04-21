module Qti
class NumericInteraction < AssessmentItemConverter
  def initialize(opts={})
    super(opts)
    @question[:question_type] = 'numerical_question'
    @type = opts[:custom_type]
  end

  def parse_question_data
    if @type == 'numeric'
      get_answer_values()
    elsif @type == 'numerical_question'
      get_canvas_answers
      attach_feedback_values(@question[:answers])
    end
    get_feedback()
    @question
  end
  
  def get_answer_values
    answer = {:weight=>100,:comments=>"",:id=>unique_local_id,:numerical_answer_type=>"range_answer"}
    @question[:answers] << answer
    if gte = @doc.at_css('responseCondition gte baseValue')
      answer[:start] = gte.text.to_f
    end
    if lte = @doc.at_css('responseCondition lte baseValue')
      answer[:end] = lte.text.to_f
    end
    if equal = @doc.at_css('responseCondition equal baseValue')
      answer[:exact] = equal.text.to_f
    end
  end
  
  def get_canvas_answers
    @doc.css('responseIf, responseElseIf').each do |r_if|
      next unless r_if.at_css('or') || r_if.at_css('and')
      answer = {:weight=>100, :id=>unique_local_id, :text=>'answer_text'}
      if or_node = r_if.at_css('or')
        # exact answer
        answer[:numerical_answer_type] = 'exact_answer'
        exact = or_node.at_css('stringMatch baseValue').text.to_f rescue 0.0
        answer[:exact] = exact
        if upper = or_node.at_css('and customOperator[class=varlte] baseValue')
          margin = upper.text.to_f - exact rescue 0.0
          answer[:margin] = margin
        end
      elsif and_node = r_if.at_css('and')
        # range answer
        answer[:numerical_answer_type] = 'range_answer'
        if upper = and_node.at_css('customOperator[class=vargte] baseValue')
          answer[:end] = upper.text.to_f rescue 0.0
        end
        if lower = and_node.at_css('customOperator[class=varlte] baseValue')
          answer[:start] = lower.text.to_f rescue 0.0
        end
      end
      answer[:feedback_id] = get_feedback_id(r_if)
      @question[:answers] << answer
    end
  end
  
end
end