require 'nokogiri'

module Qti
class ExtendedTextInteraction < AssessmentItemConverter
  include Canvas::Migration::XMLHelper
  
  def initialize(opts)
    super(opts)
  end

  def parse_question_data
    process_response_conditions
    if @question[:answers].present?
      @question[:question_type] ||= "short_answer_question"
      attach_feedback_values(@question[:answers])
    else
      # a short answer question with no answers is an essay question
      @question[:question_type] = "essay_question"
    end
    
    get_feedback
    
    @question
  end

  private
  def process_response_conditions
    fib_map = {}
    if @question[:is_vista_fib]
      #todo: refactor Blackboard FIB stuff into FillInTheBlank class
      # if it's a vista fill in the blank we need to change the FIB01 labels to the blank name in the question text
      regex = /\[([^\]]*)\]/
      count = 0
      match_data = regex.match(@question[:question_text])
      while match_data
        count += 1
        fib_map["FIB%02i" % count] = match_data[1]
        match_data = regex.match(match_data.post_match)
      end
      @question.delete :is_vista_fib
    elsif @question[:question_type] == 'fill_in_multiple_blanks_question' 
      # the python tool "fixes" IDs that aren't quite legal QTI (e.g., "1a" becomes "RESPONSE_1a")
      # but does not update the question text, breaking fill-in-multiple-blanks questions.
      # fortunately it records what it does in an XML comment at the top of the doc, so we can undo it.
      if comment = @doc.children.find { |el| el.class == Nokogiri::XML::Comment }
        regex = /Warning: replacing bad NMTOKEN "([^"]+)" with "([^"]+)"/
        match_data = regex.match(comment.text)
        while match_data
          fib_map[match_data[2]] = match_data[1]
          match_data = regex.match(match_data.post_match)
        end
      end
    end

    @doc.search('responseProcessing responseCondition').each do |cond|
      cond.css('stringMatch,match').each do |match|
        text = get_node_val(match, 'baseValue[baseType=string]')
        text ||= get_node_val(match, 'baseValue[baseType=identifier]')
        existing = false
        if @question[:question_type] != 'fill_in_multiple_blanks_question' and answer = @question[:answers].find { |a| a[:text] == text }
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
          answer[:blank_id] = fib_map[id] || id
          # strip illegal characters from blank ids
          cleaned = answer[:blank_id].gsub(/[^A-Za-z0-9\-._]/, '-')
          if answer[:blank_id] != cleaned
            @question[:question_text].gsub!("[#{answer[:blank_id]}]", "[#{cleaned}]")
            answer[:blank_id] = cleaned
          end
          if !@question[:question_text].include?("[#{cleaned}]")
            @question[:question_text] += " [#{cleaned}]"
          end
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
