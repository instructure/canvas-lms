module Qti
class NumericInteraction < AssessmentItemConverter
  def initialize(opts={})
    super(opts)
    @question[:question_type] = 'numerical_question'
  end

  def parse_question_data
    get_answer_values()
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
  
end
end