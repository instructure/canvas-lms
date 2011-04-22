module Qti
class FillInTheBlank < AssessmentItemConverter

  def initialize(opts)
    super(opts)
    @type = opts[:custom_type]
    @question[:question_type] = 'fill_in_multiple_blanks_question'
  end

  def parse_question_data
    if @type == 'angel'
      process_angel
    end
    get_feedback

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
          answer[:weight] = 100
          answer[:comments] = ""
          answer[:id] = unique_local_id
          answer[:blank_id] = get_node_att(match, 'variable', 'identifier')
        end
      end
    end

  end
end
end
