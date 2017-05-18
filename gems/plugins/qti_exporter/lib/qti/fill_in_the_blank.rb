#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Qti
class FillInTheBlank < AssessmentItemConverter

  def initialize(opts)
    super(opts)
    @type = opts[:custom_type]
    if @type == 'multiple_dropdowns_question' || @type == 'inline_choice'
      @question[:question_type] = 'multiple_dropdowns_question'
    else
      @question[:question_type] = 'fill_in_multiple_blanks_question'
    end
  end

  def parse_question_data
    if @type == 'angel'
      process_angel
    elsif @type == 'fillinmultiple'
      process_respondus
    elsif @type == 'text_entry_interaction'
      process_text_entry
    elsif @type == 'inline_choice'
      process_inline
    elsif @doc.at_css('itemBody extendedTextInteraction')
      process_d2l
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
      cond.css('stringMatch,substring,equalRounded,equal').each do |match|
        answer = {}
        node = match.at_css('baseValue[baseType=string],baseValue[baseType=integer],baseValue[baseType=float]')
        answer[:text] = node.text.strip if node
        unless answer[:text].blank?
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
        answer[:text] = choice.text.strip
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

  def process_inline
    create_xml_doc
    answer_hash = {}
    body = recursively_get_inline_body_and_answers(@doc.at_css('itemBody'), "", answer_hash)
    @question[:question_text] = body

    @doc.css('responseDeclaration').each do |res_node|
      res_id = res_node['identifier']
      res_node.css('correctResponse value').each do |correct_id|
        if answer = answer_hash[correct_id.text]
          answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
        end
      end
    end
  end

  def recursively_get_inline_body_and_answers(node, body, answer_hash)
    node.children.each do |child|
      if child.name == 'inlineChoiceInteraction'
        body += "[#{child['responseIdentifier']}]"
        child.search('inlineChoice').each do |choice|
          answer = {}
          answer[:id] = unique_local_id
          answer[:migration_id] = choice['identifier']
          answer[:text] = choice.text.strip
          answer[:blank_id] = child['responseIdentifier']
          @question[:answers] << answer
          answer_hash[choice['identifier']] = answer
        end
      elsif child.name == 'text'
        body += child.text.gsub(']]>', '').gsub('<div></div>', '').strip
      else
        body += recursively_get_inline_body_and_answers(child, body, answer_hash)
      end
    end
    body
  end

  def process_d2l
    @question[:question_text] = ''
    if body = @doc.at_css('itemBody')
      body.children.each do |node|
        next if node.name == 'text'
        text = ''
        if node.name == 'div'
          text = sanitize_html_string(node.text, true)
        elsif node.name == 'extendedTextInteraction'
          id = node['responseIdentifier']
          text = " [#{id}] "
        end
        @question[:question_text] += text
      end
    end

    @doc.css('responseCondition stringMatch').each do |match|
      if blank_id = get_node_att(match, 'variable','identifier')
        text = get_node_val(match, 'baseValue')
        answer = {:id => unique_local_id, :weight => AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT}
        answer[:migration_id] = blank_id
        answer[:text] = sanitize_html_string(text, true)
        answer[:blank_id] = blank_id
        @question[:answers] << answer
      end
    end

  end

  def process_respondus
    @doc.css('responseCondition stringMatch baseValue[baseType=string]').each do |val_node|
      if blank_id = val_node['identifier']
        blank_id = blank_id.sub(%r{^RESPONSE_-([^-]*)-}, '\1')
        @question[:answers] << {
          :weight => AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT,
          :id => unique_local_id,
          :migration_id => blank_id,
          :text => sanitize_html_string(val_node.text, true),
          :blank_id => blank_id,
        }
      end
    end
  end

  def process_text_entry
    @doc.css('responseDeclaration').each do |res_node|
      res_id = res_node['identifier']
      res_node.css('correctResponse value').each do |correct_id|
        answer = {}
        answer[:id] = unique_local_id
        answer[:weight] = DEFAULT_CORRECT_WEIGHT
        answer[:text] = correct_id.text
        answer[:blank_id] = res_id
        @question[:answers] << answer
      end
    end
  end

end
end
