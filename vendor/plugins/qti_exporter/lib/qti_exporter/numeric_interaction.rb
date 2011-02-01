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
    if gte = @doc.at_css('responsecondition gte basevalue')
      answer[:start] = gte.text.to_f
    end
    if lte = @doc.at_css('responsecondition lte basevalue')
      answer[:end] = lte.text.to_f
    end
    if equal = @doc.at_css('responsecondition equal basevalue')
      answer[:exact] = equal.text.to_f
    end
  end
  
end
end