module Qti
class FillInTheBlank < AssessmentItemConverter

  def initialize(opts)
    super(opts)
    @type = opts[:custom_type]
    if @type == 'multiple_dropdowns_question'
      @question[:question_type] = 'multiple_dropdowns_question'
    else
      @question[:question_type] = 'fill_in_multiple_blanks_question'
    end
  end

  def parse_question_data
    if @type == 'angel'
      process_angel
    else
      process_canvas
    end
    get_feedback
    @question[:answers].each{|a|a.delete :migration_id}
    @question
  end

  private
  def process_angel
    create_xml_doc
    body = ""
    @doc.at_css('itemBody').children.each do |child|
      if child.name == 'textEntryInteraction'
        body += " [#{child['responseIdentifier']}] "
      else
        body += child.text.gsub(']]>', '').gsub('<div></div>', '').strip
      end
    end
    @question[:question_text] = body

    @doc.search('responseProcessing responseCondition').each do |cond|
      cond.css('stringMatch').each do |match|
        answer = {}
        answer[:text] = match.at_css('baseValue[baseType=string]').text.strip
        unless answer[:text] == ""
          @question[:answers] << answer
          answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
          answer[:comments] = ""
          answer[:id] = unique_local_id
          answer[:blank_id] = get_node_att(match, 'variable', 'identifier')
        end
      end
    end

  end
  
  def process_canvas
    answer_hash = {}
    @doc.css('choiceInteraction').each do |ci|
      if blank_id = ci['responseIdentifier']
        blank_id.gsub!(/^response_/, '')
      end
      ci.search('simpleChoice').each do |choice|
        answer = {}
        answer[:weight] = @type == 'multiple_dropdowns_question' ? 0 : 100
        answer[:id] = unique_local_id
        answer[:migration_id] = choice['identifier']
        answer[:text] = clear_html choice.text.strip.gsub(/\s+/, " ")
        answer[:blank_id] = blank_id
        @question[:answers] << answer
        answer_hash[choice['identifier']] = answer
      end
    end
    
    if @type == 'multiple_dropdowns_question'
      @doc.css('responseProcessing responseCondition responseIf,responseElseIf').each do |if_node|
        if if_node.at_css('setOutcomeValue[identifier=SCORE] sum')
          id = if_node.at_css('match baseValue[baseType=identifier]').text
          if answer = answer_hash[id]
            answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
          end
        end
      end
    end
  end
  
end
end
