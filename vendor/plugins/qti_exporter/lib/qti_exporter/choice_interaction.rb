module Qti
class ChoiceInteraction < AssessmentItemConverter
  extend Canvas::XMLHelper
  TEST_FILE = "/home/bracken/projects/QTIMigrationTool/assessments/out/assessmentItems/ID_4388459047391.xml"
  DEFAULT_ANSWER_TEXT = "No answer text provided."

  def initialize(opts)
    super(opts)
    @is_really_stupid_likert = opts[:interaction_type] == 'stupid_likert_scale_question'
  end

  def parse_question_data
    answers_hash = {}
    get_answers(answers_hash)
    process_response_conditions(answers_hash)
    attach_feedback_values(answers_hash)
    set_question_type
    get_feedback
    process_either_or_question
    @question
  end

  private

  def is_either_or
    @migration_type =~ /either\/or/i
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
    if correct_answers == 0
      @question[:import_error] = "The importer couldn't determine the correct answers for this question."
    end
    @question[:question_type] ||= correct_answers == 1 ? "multiple_choice_question" : "multiple_answers_question"
    @question[:question_type] = 'multiple_choice_question' if @is_really_stupid_likert
  end

  # creates an answer hash for each of the available options
  def get_answers(answers_hash)
    @doc.css('choiceinteraction').each do |ci|
      ci.search('simplechoice').each do |choice|
        answer = {}
        answer[:weight] = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
        answer[:id] = unique_local_id
        answer[:migration_id] = choice['identifier']
        answer[:text] = clear_html choice.text.strip.gsub(/\s+/, " ")
        node = sanitize_html!(choice)
        if (sanitized = node.inner_html.strip) != answer[:text]
          answer[:html] = sanitized
        end
        if answer[:text] == ""
          if answer[:migration_id] =~ /true|false/i
            answer[:text] = clear_html(answer[:migration_id])
          else
            answer[:text] = DEFAULT_ANSWER_TEXT
          end
        end
        @question[:answers] << answer
        if ci['responseidentifier'] and @question[:question_type] == 'multiple_dropdowns_question'
          answer[:blank_id] = ci['responseidentifier']
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
      @doc.css('choicetablecolumns choicetablecolumn').each do |cc|
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
    @doc.search('responseprocessing responsecondition').each do |cond|
      if @question[:question_type] == 'multiple_dropdowns_question'
        cond.css('match').each do |match|
          blank_id = match.at_css('variable @identifier').text
          migration_id = match.at_css('basevalue').text
          answer = answers_hash["#{blank_id}_#{migration_id}"]
          answer[:weight] = get_response_weight(cond)
        end
      elsif cond.at_css('match variable[identifier=RESP_MC]') or cond.at_css('match variable[identifier=response]')
        migration_id = cond.at_css('match basevalue[basetype=identifier]').text.strip()
        migration_id = migration_id.sub('.', '_') if is_either_or
        answer = answers_hash[migration_id]
        answer[:weight] = get_response_weight(cond)
        answer[:feedback_id] = get_feedback_id(cond)
      elsif cond.at_css('member variable[identifier=RESP_MC]')
        migration_id = cond.at_css('member basevalue[basetype=identifier]').text
        answer = answers_hash[migration_id]
        answer[:weight] = get_response_weight(cond)
        answer[:feedback_id] = get_feedback_id(cond)
      elsif cond.at_css('match variable[identifier^=TF]')
        migration_id = cond.at_css('match basevalue[basetype=identifier]').text
        answer = answers_hash[migration_id]
        answer[:weight] = get_response_weight(cond)
        answer[:feedback_id] = get_feedback_id(cond)
        @question[:question_type] = "true_false_question"
      elsif cond.at_css('and > member')
        cond.css('and > member').each do |m|
          migration_id = m.at_css('basevalue[basetype=identifier]').text.strip()
          answer = answers_hash[migration_id]
          answer[:weight] = get_response_weight(cond)
          answer[:feedback_id] = get_feedback_id(cond)
        end
      else
        cond.css('responseif, responseelseif').each do |r_if|
          migration_id = r_if.at_css('match basevalue[basetype=identifier]')
          migration_id ||= r_if.at_css('member basevalue[basetype=identifier]')
          if migration_id
            migration_id = migration_id.text.strip()
            if answer = answers_hash[migration_id]
              answer[:weight] = get_response_weight(r_if)
              answer[:feedback_id] = get_feedback_id(r_if)
            end
          end
        end
        @question[:feedback_id] = get_feedback_id(cond)
      end
    end

    #Check if there are correct answers explicitly specified
    @doc.css('correctresponse > value').each do |correct_id|
      correct_id = correct_id.text if correct_id
      if correct_id && answer = answers_hash[correct_id]
        answer[:weight] = DEFAULT_CORRECT_WEIGHT
      end
    end
  end

  # Sets the actual feedback values and clears the feedback ids
  def attach_feedback_values(answers_hash)
    feedback_hash = {}
    @doc.search('modalfeedback[outcomeidentifier=FEEDBACK]').each do |feedback|
      id = feedback['identifier']
      text = clear_html(feedback.at_css('p').text.gsub(/\s+/, " ")).strip
      feedback_hash[id] = text

      if @question[:feedback_id] == id
        @question[:correct_comments] = text
        @question[:incorrect_comments] = text
      end
    end

    #clear extra entries
    @question.delete :feedback_id
    answers_hash.each_key do |key|
      answer = answers_hash[key]
      if feedback_hash.has_key? answer[:feedback_id]
        answer[:comments] = feedback_hash[answer[:feedback_id]]
      end
      answer.delete :feedback_id
    end
  end

  # pulls the feedback id from the condition
  def get_feedback_id(cond)
    id = nil

    if feedback = cond.at_css('setoutcomevalue[identifier=FEEDBACK]')
      if feedback.at_css('variable[identifier=FEEDBACK]')
        if feedback = feedback.at_css('basevalue[basetype=identifier]')
          id = feedback.text.strip
        end
      end
    end
    id
  end

  # parses the wight of a response to determine whether it is a correct response
  def get_response_weight(cond)
    weight = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
    
    if sum = cond.at_css('setoutcomevalue[identifier=SCORE] sum basevalue[basetype]')
      #it'll only be true if the score is a sum > 0
      weight = get_base_value(sum)
    elsif base = cond.at_css('setoutcomevalue[identifier=SCORE] > basevalue[basetype]')
      weight = get_base_value(base)
    elsif base = cond.at_css('setoutcomevalue[identifier^=SCORE] basevalue[basetype]')
      weight = get_base_value(base)
    elsif base = cond.at_css('setoutcomevalue[identifier$=SCORE] basevalue[basetype]')
      weight = get_base_value(base)
    end

    weight
  end

  def get_base_value(node)
    weight = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
    if node['basetype'] == "float" #base_value = node.at_css('basevalue[basetype=float]')
      if node.text =~ /score\.max/i or node.text.to_f > 0
        weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
      end
    elsif node['basetype'] == "integer" #elsif base_value = node.at_css('basevalue[basetype=integer]')
      if node.text.to_i > 0
        weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
      end
    elsif node['basetype'] == "boolean"  #elsif base_value = node.at_css('basevalue[basetype=boolean]')
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