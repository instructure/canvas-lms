module Qti
class ExtendedTextInteraction < AssessmentItemConverter

  def initialize(opts)
    super(opts)
    @short_answer = opts[:interaction_type] =~ /short_answer_question/i ? true : false
  end

  def parse_question_data
    if !@short_answer
      @short_answer = @doc.at_css('setoutcomevalue[identifier=SCORE]') || @doc.at_css('setoutcomevalue[identifier$=SCORE]') || @doc.at_css('setoutcomevalue[identifier^=SCORE]')
    end
    if @short_answer
      @question[:question_type] ||= "short_answer_question"
      process_response_conditions
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
    @doc.search('responseprocessing responsecondition').each do |cond|
      cond.css('stringmatch').each do |match|
        answer = {}
        answer[:text] = match.at_css('basevalue[basetype=string]').text.strip
        if @question[:question_type] == 'fill_in_multiple_blanks_question' and id = match.at_css('variable @identifier')
          id = id.text.strip
          answer[:blank_id] = vista_fib_map[id] || id
        end
        unless answer[:text] == ""
          @question[:answers] << answer
          answer[:weight] = 100
          answer[:comments] = ""
          answer[:id] = unique_local_id
        end
      end
    end
    #Check if there are correct answers explicitly specified
    @doc.css('correctresponse value').each do |correct_id|
      answer = {}
      answer[:id] = unique_local_id
      answer[:weight] = DEFAULT_CORRECT_WEIGHT
      answer[:text] = correct_id.text
      @question[:answers] << answer
    end
  end
end
end
