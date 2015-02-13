module Qti
class ChoiceInteraction < AssessmentItemConverter
  extend Canvas::Migration::XMLHelper
  TEST_FILE = "/home/bracken/projects/QTIMigrationTool/assessments/out/assessmentItems/ID_4388459047391.xml"
  DEFAULT_ANSWER_TEXT = "No answer text provided."

  def initialize(opts)
    super(opts)
    @is_really_stupid_likert = opts[:interaction_type] == 'stupid_likert_scale_question'
    @use_set_var_set_as_correct = @flavor == Qti::Flavors::RESPONDUS
  end

  def parse_question_data
    answers_hash = {}
    get_answers(answers_hash)
    process_response_conditions(answers_hash)
    attach_feedback_values(answers_hash.values)
    set_question_type
    get_feedback
    process_true_false_question
    process_either_or_question
    @question
  end

  private

  def is_either_or
    @migration_type =~ /either\/or/i
  end

  def process_true_false_question
    # ensure that the answers have a consistent format with our own
    if @question[:question_type] == "true_false_question"
      valid = false
      if @question[:answers].count == 2
        true_answer = @question[:answers].detect{|a| a[:text] =~ /true/i }
        false_answer = @question[:answers].detect{|a| a != true_answer && a[:text] =~ /false/i }

        if true_answer && false_answer
          valid = true
          true_answer[:text] = "True"
          false_answer[:text] = "False"
          @question[:answers] = [true_answer, false_answer]
        end
      end

      @question[:question_type] = 'multiple_choice_question' unless valid
    end
  end

  def process_either_or_question
    if is_either_or
      @question[:answers].each do |a|
        split = a[:text].split(/_|\./)
        a[:text] = split[2] =~ /true/i ? split[0] : split[1]
      end
    end
  end

  def set_question_type
    correct_answers = 0
    @question[:answers].each do |ans|
      correct_answers += 1 if ans[:weight] and ans[:weight] > 0
    end
    
    # If the question is worth zero points its correct answer's weight might
    # be zero even though it's correct. The convention is that the score is set
    # instead of added to. So set that answer to correct in that case.
    if correct_answers == 0 && @use_set_var_set_as_correct
      @question[:answers].each do |ans|
        if ans[:zero_weight_set_not_summed]
          ans.delete :zero_weight_set_not_summed
          ans[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
          correct_answers += 1
        end
      end
    end

    if correct_answers == 0
      @question[:import_error] = "The importer couldn't determine the correct answers for this question."
    end
    @question[:question_type] ||= correct_answers == 1 ? "multiple_choice_question" : "multiple_answers_question"
    @question[:question_type] = 'multiple_choice_question' if @is_really_stupid_likert
  end

  # creates an answer hash for each of the available options
  def get_answers(answers_hash)
    @doc.css('choiceInteraction').each do |ci|
      ci.search('simpleChoice').each do |choice|
        answer = {}
        answer[:weight] = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
        answer[:id] = unique_local_id
        answer[:migration_id] = choice['identifier']
        
        if feedback = choice.at_css('feedbackInline')
          # weird Angel feedback
          answer[:text] = choice.children.first.text.strip
          answer[:comments] = feedback.text.strip
        else
          answer[:text] = clear_html(choice.text).strip.gsub(/\s+/, " ")
          if choice.at_css('div[class=text]')
            answer[:text] = choice.text.strip
          else
            sanitized = sanitize_html!(choice.at_css('div[class=html]') ? Nokogiri::HTML::DocumentFragment.parse(choice.text) : choice, true)
            if sanitized.present? && sanitized != CGI::escapeHTML(answer[:text])
              answer[:html] = sanitized
            end
          end
        end
        
        if answer[:text] == ""
          if answer[:migration_id] =~ /true|false/i
            answer[:text] = clear_html(answer[:migration_id])
          else
            answer[:text] = DEFAULT_ANSWER_TEXT
          end
        end
        if @flavor == Qti::Flavors::BBLEARN && @question[:question_type] == 'true_false_question' && choice['identifier'] =~ /true|false/i
          answer[:text] = choice['identifier']
        end

        @question[:answers] << answer
        if ci['responseIdentifier'] and @question[:question_type] == 'multiple_dropdowns_question'
          answer[:blank_id] = ci['responseIdentifier']
          answers_hash["#{answer[:blank_id]}_#{answer[:migration_id]}"] = answer
        else
          answers_hash[answer[:migration_id]] = answer
        end
      end
    end

    # This is only seen in an Angel likert scale
    # Angel can have a whole table of options but we're
    # just grabbing one dimension of it
    if @is_really_stupid_likert
      @doc.css('choiceTableColumns choiceTableColumn').each do |cc|
        answer = {}
        answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
        answer[:id] = unique_local_id
        answer[:migration_id] = cc['id']
        answer[:text] = cc['label']
        @question[:answers] << answer if answer[:text]
      end
    end
  end

  # pulls the weights and response ids from the responseConditions
  def process_response_conditions(answers_hash)
    @doc.search('responseProcessing responseCondition').each do |cond|
      if @question[:question_type] == 'multiple_dropdowns_question'
        cond.css('match').each do |match|
          blank_id = get_node_att(match,'variable', 'identifier')
          migration_id = match.at_css('baseValue').text
          answer = answers_hash["#{blank_id}_#{migration_id}"]
          answer[:weight] = get_response_weight(cond)
        end
      elsif cond.at_css('match variable[identifier=RESP_MC]') or cond.at_css('match variable[identifier=response]')
        migration_id = cond.at_css('match baseValue[baseType=identifier]').text.strip()
        migration_id = migration_id.sub('.', '_') if is_either_or
        answer = answers_hash[migration_id] || answers_hash.values.detect{|a| a[:text] == migration_id}
        answer[:weight] = get_response_weight(cond)
        answer[:feedback_id] ||= get_feedback_id(cond)
      elsif cond.at_css('member variable[identifier=RESP_MC]')
        migration_id = cond.at_css('member baseValue[baseType=identifier]').text
        answer = answers_hash[migration_id]
        answer[:weight] = get_response_weight(cond)
        answer[:feedback_id] ||= get_feedback_id(cond)
      elsif cond.at_css('match variable[identifier^=TF]')
        migration_id = cond.at_css('match baseValue[baseType=identifier]').text
        answer = answers_hash[migration_id]
        answer[:weight] = get_response_weight(cond)
        answer[:feedback_id] ||= get_feedback_id(cond)
        @question[:question_type] = "true_false_question"
      elsif cond.at_css('responseIf and > member')
        cond.css('responseIf > and > member').each do |m|
          migration_id = m.at_css('baseValue[baseType=identifier]').text.strip()
          answer = answers_hash[migration_id]
          answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
          answer[:feedback_id] ||= get_feedback_id(cond)
        end
      else
        cond.css('responseIf, responseElseIf').each do |r_if|
          migration_id = r_if.at_css('match baseValue[baseType=identifier]')
          migration_id ||= r_if.at_css('member baseValue[baseType=identifier]')
          if migration_id
            migration_id = migration_id.text.strip()

            answer = answers_hash[migration_id]
            answer ||= answers_hash.values.detect{|a| a[:text] == migration_id}

            if answer
              answer[:weight] = get_response_weight(r_if)
              answer[:feedback_id] ||= get_feedback_id(r_if)
              
              #flag whether this answer was set or added to
              if @use_set_var_set_as_correct
                if answer[:weight] == 0 && r_if.at_css('setOutcomeValue[identifier=QUE_SCORE] > baseValue[baseType]')
                  answer[:zero_weight_set_not_summed] = true
                end
              end
              
            end
          end
        end
        @question[:feedback_id] = get_feedback_id(cond)
      end
    end

    #Check if there are correct answers explicitly specified
    @doc.css('correctResponse > value, correctResponse > Value').each do |correct_id|
      correct_id = correct_id.text if correct_id
      if correct_id && answer = answers_hash[correct_id]
        answer[:weight] = DEFAULT_CORRECT_WEIGHT
      end
    end
  end

  # parses the wight of a response to determine whether it is a correct response
  def get_response_weight(cond)
    weight = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
    
    if sum = cond.at_css('setOutcomeValue[identifier=SCORE] sum baseValue[baseType]')
      #it'll only be true if the score is a sum > 0
      weight = get_base_value(sum)
    elsif sum = cond.at_css('setOutcomeValue[identifier=D2L_CORRECT] sum baseValue[baseType]')
      weight = get_base_value(sum)
    elsif base = cond.at_css('setOutcomeValue[identifier=SCORE] > baseValue[baseType]')
      weight = get_base_value(base)
    elsif base = cond.at_css('setOutcomeValue[identifier^=SCORE] baseValue[baseType]')
      weight = get_base_value(base)
    elsif base = cond.at_css('setOutcomeValue[identifier$=SCORE] baseValue[baseType]')
      weight = get_base_value(base)
    end

    weight
  end

  def get_base_value(node)
    weight = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
    if node['baseType'] == "float" #base_value = node.at_css('baseValue[baseType=float]')
      if node.text =~ /score\.max/i or node.text.to_f > 0
        weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
      end
    elsif node['baseType'] == "integer" #elsif base_value = node.at_css('baseValue[baseType=integer]')
      if node.text.to_i > 0
        weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
      end
    elsif node['baseType'] == "boolean"  #elsif base_value = node.at_css('baseValue[baseType=boolean]')
      if node.text.downcase == "true"
        weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
      end
    else
      @log.warn "The type of the weight value was not recognized, defaulting to: #{AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT}"
    end
    
    weight
  end

end
end
