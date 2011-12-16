module Qti
class OrderInteraction < AssessmentItemConverter
  def initialize(opts)
    super(opts)
    @question[:matches] = []
    @question[:question_type] = 'matching_question'
  end

  def parse_question_data
    match_map = {}
    get_all_matches(match_map)
    if node = @doc.at_css('correctResponse')
      get_correct_responses(match_map)
    else
      get_all_answers(match_map)
    end
    get_feedback()
    @question
  end
  
  def get_all_matches(match_map)
    if matches = @doc.at_css('orderInteraction')
      matches.css('simpleChoice').each do |sc|
        match = {}
        @question[:matches] << match
        match[:text] = clear_html(sc.text.strip)
        match[:match_id] = unique_local_id
        match_map[sc['identifier']] = match[:match_id]
      end
    end
  end
  
  def get_all_answers(match_map)
    @doc.css('responseCondition member').each_with_index do |a, i|
      answer = {}
      @question[:answers] << answer
      answer[:text] = "#{i + 1}"
      answer[:id] = unique_local_id 
      answer[:comments] = ""
      
      if option = a.at_css('baseValue')
        answer[:match_id] = match_map[option.text.strip]
      end
    end
  end

  def get_correct_responses(match_map)
    @doc.css('correctResponse > value').each_with_index do |answ, i|
      answer = {}
      @question[:answers] << answer
      answer[:text] = "#{i + 1}"
      answer[:id] = unique_local_id
      answer[:comments] = ""

      match_id = answ.text.strip
      if m = match_map[match_id]
        answer[:match_id] = m
      end
    end
  end
  
end
end