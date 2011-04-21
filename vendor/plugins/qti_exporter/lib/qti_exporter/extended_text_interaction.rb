module Qti
class ExtendedTextInteraction < AssessmentItemConverter

  def initialize(opts)
    super(opts)
    @short_answer = opts[:interaction_type] =~ /short_answer_question/i ? true : false
  end

  def parse_question_data
    if !@short_answer
      @short_answer = @doc.at_css('setOutcomeValue[identifier=SCORE]') || @doc.at_css('setOutcomeValue[identifier$=SCORE]') || @doc.at_css('setOutcomeValue[identifier^=SCORE]')
    end
    if @short_answer
      @question[:question_type] ||= "short_answer_question"
      process_response_conditions
      attach_feedback_values(@question[:answers])
    else
      @question[:question_type] ||= "essay_question"
    end
    
    get_feedback
    
    @question
  end

  private
  def process_response_conditions
    vista_fib_map = {}
    if @question[:is_vista_fib]
      #todo: refactor Blackboard FIB stuff into FillInTheBlank class
      # if it's a vista fill in the blank we need to change the FIB01 labels to the blank name in the question text
      regex = /\[([^\]]*)\]/
      count = 0
      match_data = regex.match(@question[:question_text])
      while match_data
        count += 1
        vista_fib_map["FIB%02i" % count] = match_data[1]
        match_data = regex.match(match_data.post_match)
      end
      @question.delete :is_vista_fib
    end
    @doc.search('responseProcessing responseCondition').each do |cond|
      cond.css('stringMatch').each do |match|
        text = match.at_css('baseValue[baseType=string]').text.strip
        existing = false
        if answer = @question[:answers].find { |a| a[:text] == text }
          existing = true
        else
          answer = {}
        end
        answer[:text] ||= text
        unless answer[:feedback_id] 
          if f_id = get_feedback_id(cond)
            answer[:feedback_id] = f_id
          end
        end
        if @question[:question_type] == 'fill_in_multiple_blanks_question' and id = get_node_att(match, 'variable', 'identifier')
          id = id.strip
          answer[:blank_id] = vista_fib_map[id] || id
        end
        unless existing || answer[:text] == ""
          @question[:answers] << answer
          answer[:weight] = 100
          answer[:comments] = ""
          answer[:id] = unique_local_id
        end
      end
    end
    #Check if there are correct answers explicitly specified
    @doc.css('correctResponse value').each do |correct_id|
      answer = {}
      answer[:id] = unique_local_id
      answer[:weight] = DEFAULT_CORRECT_WEIGHT
      answer[:text] = correct_id.text
      @question[:answers] << answer
    end
  end
end
end
