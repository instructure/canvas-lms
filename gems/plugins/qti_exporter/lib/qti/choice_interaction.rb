# frozen_string_literal: true

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

require "nokogiri"

module Qti
  class ChoiceInteraction < AssessmentItemConverter
    extend Canvas::Migration::XMLHelper
    TEST_FILE = "/home/bracken/projects/QTIMigrationTool/assessments/out/assessmentItems/ID_4388459047391.xml"
    DEFAULT_ANSWER_TEXT = "No answer text provided."

    def initialize(opts)
      super(opts)
      @is_really_stupid_likert = opts[:interaction_type] == "stupid_likert_scale_question"
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
      @migration_type =~ %r{either/or}i
    end

    def process_true_false_question
      # ensure that the answers have a consistent format with our own
      if @question[:question_type] == "true_false_question"
        valid = false
        if @question[:answers].count == 2
          true_answer = @question[:answers].detect { |a| a[:text] =~ /true/i }
          false_answer = @question[:answers].detect { |a| a != true_answer && a[:text] =~ /false/i }

          if true_answer && false_answer
            valid = true
            true_answer[:text] = "True"
            false_answer[:text] = "False"
            @question[:answers] = [true_answer, false_answer]
          end
        end

        @question[:question_type] = "multiple_choice_question" unless valid
      end
    end

    def process_either_or_question
      if is_either_or
        @question[:answers].each do |a|
          split = a[:text].split(/_|\./)
          a[:text] = /true/i.match?(split[2]) ? split[0] : split[1]
        end
      end
    end

    def set_question_type
      correct_answers = 0
      @question[:answers].each do |ans|
        correct_answers += 1 if ans[:weight] && ans[:weight] > 0
      end

      # If the question is worth zero points its correct answer's weight might
      # be zero even though it's correct. The convention is that the score is set
      # instead of added to. So set that answer to correct in that case.
      if correct_answers == 0 && @use_set_var_set_as_correct
        @question[:answers].each do |ans|
          next unless ans[:zero_weight_set_not_summed]

          ans.delete :zero_weight_set_not_summed
          ans[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
          correct_answers += 1
        end
      end

      if correct_answers == 0
        @question[:import_error] = "The importer couldn't determine the correct answers for this question."
      end
      @question[:question_type] ||= (correct_answers == 1) ? "multiple_choice_question" : "multiple_answers_question"
      @question[:question_type] = "multiple_choice_question" if @is_really_stupid_likert
    end

    # creates an answer hash for each of the available options
    def get_answers(answers_hash)
      @doc.css("choiceInteraction").each do |ci|
        ci.search("simpleChoice").each do |choice|
          answer = {}
          answer[:weight] = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
          answer[:migration_id] = choice["identifier"]
          answer[:id] = get_or_generate_answer_id(answer[:migration_id])

          if (feedback = choice.at_css("feedbackInline"))
            # weird Angel feedback
            answer[:text] = choice.children.first.text.strip
            answer[:comments] = feedback.text.strip
          else
            answer[:text] = clear_html(choice.text).strip.gsub(/\s+/, " ")
            if choice.at_css("div[class=text]")
              answer[:text] = choice.text.strip
            else
              sanitized = sanitize_html!(choice.at_css("div[class=html]") ? Nokogiri::HTML5.fragment(choice.text) : choice, true)
              if sanitized.present? && sanitized != CGI.escapeHTML(answer[:text])
                answer[:html] = sanitized
              end
            end
          end

          if answer[:text] == ""
            answer[:text] = if /true|false/i.match?(answer[:migration_id])
                              clear_html(answer[:migration_id])
                            else
                              DEFAULT_ANSWER_TEXT
                            end
          end
          if @flavor == Qti::Flavors::BBLEARN && @question[:question_type] == "true_false_question" && choice["identifier"] =~ /true|false/i
            answer[:text] = choice["identifier"]
          end

          @question[:answers] << answer
          if ci["responseIdentifier"] && @question[:question_type] == "multiple_dropdowns_question"
            answer[:blank_id] = ci["responseIdentifier"]
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
        @doc.css("choiceTableColumns choiceTableColumn").each do |cc|
          answer = {}
          answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
          answer[:id] = unique_local_id
          answer[:migration_id] = cc["id"]
          answer[:text] = cc["label"]
          @question[:answers] << answer if answer[:text]
        end
      end
    end

    # pulls the weights and response ids from the responseConditions
    def process_response_conditions(answers_hash)
      @doc.search("responseProcessing responseCondition").each do |cond|
        if @question[:question_type] == "multiple_dropdowns_question"
          cond.css("match").each do |match|
            blank_id = get_node_att(match, "variable", "identifier")
            migration_id = match.at_css("baseValue").text
            answer = answers_hash["#{blank_id}_#{migration_id}"]
            answer[:weight] = get_response_weight(cond)
          end
        elsif @doc.at_css('instructureField[name="bb_question_type"][value="Multiple Answer"]') &&
              @doc.at_css("responseIf > and > match")
          process_blackboard_9_multiple_answers(answers_hash)
        elsif cond.at_css("match variable[identifier=RESP_MC]") || cond.at_css("match variable[identifier=response]")
          migration_id = cond.at_css("match baseValue[baseType=identifier]").text.strip
          migration_id = migration_id.sub(".", "_") if is_either_or
          answer = answers_hash[migration_id] || answers_hash.values.detect { |a| a[:text] == migration_id }
          answer[:weight] = get_response_weight(cond)
          answer[:feedback_id] ||= get_feedback_id(cond)
        elsif cond.at_css("member variable[identifier=RESP_MC]")
          migration_id = cond.at_css("member baseValue[baseType=identifier]").text
          answer = answers_hash[migration_id]
          answer[:weight] = get_response_weight(cond)
          answer[:feedback_id] ||= get_feedback_id(cond)
        elsif cond.at_css("match variable[identifier^=TF]")
          migration_id = cond.at_css("match baseValue[baseType=identifier]").text
          answer = answers_hash[migration_id]
          answer[:weight] = get_response_weight(cond)
          answer[:feedback_id] ||= get_feedback_id(cond)
          @question[:question_type] = "true_false_question"
        elsif cond.at_css("responseIf and > member")
          cond.css("responseIf > and > member").each do |m|
            migration_id = m.at_css("baseValue[baseType=identifier]").text.strip
            answer = answers_hash[migration_id]
            answer ||= guess_answer_by_position(cond, migration_id, answers_hash)
            next unless answer

            answer[:weight] = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
            answer[:feedback_id] ||= get_feedback_id(cond)
            # an import error will be logged later if there are no correct answers
          end
        else
          cond.css("responseIf, responseElseIf").each do |r_if|
            migration_id = r_if.at_css("match baseValue[baseType=identifier]")
            migration_id ||= r_if.at_css("member baseValue[baseType=identifier]")
            if migration_id
              migration_id = migration_id.text.strip

              answer = answers_hash[migration_id]
              answer ||= answers_hash.values.detect { |a| a[:text]&.casecmp?(migration_id) }

              if answer
                answer[:weight] = get_response_weight(r_if)
                answer[:feedback_id] ||= get_feedback_id(r_if)

                # flag whether this answer was set or added to
                if @use_set_var_set_as_correct && (answer[:weight] == 0 && r_if.at_css("setOutcomeValue[identifier=QUE_SCORE] > baseValue[baseType]"))
                  answer[:zero_weight_set_not_summed] = true
                end
              end
            end
            next if @question[:points_possible]

            que_scores = cond.css("setOutcomeValue[identifier=QUE_SCORE] > baseValue[baseType]")
            if que_scores.any?
              @question[:points_possible] = que_scores.map { |q| q.text.to_i }.max
            end
          end
          @question[:feedback_id] = get_feedback_id(cond)
        end
      end

      # Check if there are correct answers explicitly specified
      @doc.css("correctResponse > value, correctResponse > Value").each do |correct_id|
        correct_id = correct_id.text if correct_id
        if correct_id && (answer = answers_hash[correct_id])
          answer[:weight] = DEFAULT_CORRECT_WEIGHT
        end
      end
    end

    # parses the wight of a response to determine whether it is a correct response
    def get_response_weight(cond)
      weight = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT

      if (base = cond.at_css("setOutcomeValue[identifier=SCORE] sum baseValue[baseType]")) ||
         (base = cond.at_css("setOutcomeValue[identifier=D2L_CORRECT] sum baseValue[baseType]")) ||
         (base = cond.at_css("setOutcomeValue[identifier=SCORE] > baseValue[baseType]")) ||
         (base = cond.at_css("setOutcomeValue[identifier^=SCORE] baseValue[baseType]")) ||
         (base = cond.at_css("setOutcomeValue[identifier$=SCORE] baseValue[baseType]"))
        # it'll only be true if the score is a sum > 0
        weight = get_base_value(base)
      end

      weight
    end

    def get_base_value(node)
      weight = AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT
      case node["baseType"]
      when "float" # base_value = node.at_css('baseValue[baseType=float]')
        if node.text =~ /score\.max/i || node.text.to_f > 0
          weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
        end
      when "integer" # elsif base_value = node.at_css('baseValue[baseType=integer]')
        if node.text.to_i > 0
          weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
        end
      when "boolean" # elsif base_value = node.at_css('baseValue[baseType=boolean]')
        if node.text.casecmp?("true")
          weight = AssessmentItemConverter::DEFAULT_CORRECT_WEIGHT
        end
      else
        @log.warn "The type of the weight value was not recognized, defaulting to: #{AssessmentItemConverter::DEFAULT_INCORRECT_WEIGHT}"
      end

      weight
    end

    # BB9 does these questions a little differently, so we will special-case them
    def process_blackboard_9_multiple_answers(answers_hash)
      and_node = @doc.at_css("responseIf > and")
      matches = and_node.css("> match").map { |match| match.at_css("baseValue[baseType=identifier]").text.strip }
      not_matches = and_node.css("> not match").map { |match| match.at_css("baseValue[baseType=identifier]").text.strip }
      get_real_blackboard_match_ids(answers_hash, matches, not_matches).each do |migration_id|
        answer = answers_hash[migration_id]
        answer[:weight] = get_response_weight(and_node.parent)
        answer[:feedback_id] ||= get_feedback_id(and_node.parent)
      end
    end

    # in a blackboard multiple-answer example given to us by a customer,
    # the answers had ids `answer_1` through `answer_4`,
    # but the response conditions referred to `answer_0` through `answer_3`...
    # so if this happens, sort the IDs and match by position. :P
    def get_real_blackboard_match_ids(answers_hash, matches, not_matches)
      actual_answer_ids = answers_hash.keys.uniq.sort
      putative_answer_ids = (matches + not_matches).uniq.sort
      if (putative_answer_ids - actual_answer_ids).empty?
        matches
      else
        matches.map { |bad_id| actual_answer_ids[putative_answer_ids.index(bad_id)] }
      end
    end

    # in BB ultra, the answer hash contains UUIDs whereas the response conditions
    # contain 128-bit hex numbers. I haven't been able to relate the two by an
    # MD5 relationship, but the disjoint ID sets seem to appear in the same order
    # in the file (although the IDs themselves are not ordered, unlike BB9)
    # so match purely by position
    def guess_answer_by_position(response_condition, response_id, answer_hash)
      response_ids = response_condition.css("responseIf > and baseValue[baseType=identifier]").map { |v| v.text.strip }
      return nil unless response_ids.size == answer_hash.size

      pos = response_ids.index(response_id)
      pos && answer_hash.values[pos]
    end
  end
end
