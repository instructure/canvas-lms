#
# Copyright (C) 2011 Instructure, Inc.
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
#
require 'bigdecimal'

module CC
  module QTI
    module QTIItems

      CC_SUPPORTED_TYPES = ['multiple_choice_question',
                            'multiple_answers_question',
                            'true_false_question',
                            'short_answer_question',
                            'essay_question']

      CC_TYPE_PROFILES = {
              'multiple_choice_question' => 'cc.multiple_choice.v0p1',
              'multiple_answers_question' => 'cc.multiple_response.v0p1',
              'true_false_question' => 'cc.true_false.v0p1',
              'short_answer_question' => 'cc.fib.v0p1',
              'essay_question' => 'cc.essay.v0p1'
      }

      # These types don't stop processing response conditions once the correct
      # answer is found, so they need to show the incorrect response differently
      MULTI_ANSWER_TYPES = ['matching_question',
                           'multiple_dropdowns_question',
                           'fill_in_multiple_blanks_question']

      def add_ref_or_question(node, question)
        aq = nil
        unless question[:assessment_question_id].blank?
          if aq = AssessmentQuestion.where(id: question[:assessment_question_id]).first
            if aq.deleted? ||
                    !aq.assessment_question_bank ||
                    aq.assessment_question_bank.deleted? ||
                    aq.assessment_question_bank.context_id != @course.id ||
                    aq.assessment_question_bank.context_type != @course.class.to_s
              aq = nil
            end
          end
        end

        if aq
          ref = CC::CCHelper::create_key(aq)
          node.itemref(:linkrefid => ref)
        else
          add_question(node, question)
        end
      end

      # if the question is a supported CC type it will be added
      # it it's not supported it's just skipped
      # returns boolean - whether the question was added
      def add_cc_question(node, question)
        return false unless CC_SUPPORTED_TYPES.member?(question['question_type'])
        add_question(node, question, true)
        true
      end

      def add_quiz_question(node, question)
        question[:is_quiz_question] = true
        add_question(node, question)
      end

      def add_question(node, question, for_cc=false)
        aq_mig_id = create_key("assessment_question_#{question['assessment_question_id']}")
        qq_mig_id = create_key("quiz_question_#{question['id']}")
        question['migration_id'] = question[:is_quiz_question] ? qq_mig_id : aq_mig_id
        question['answers'] ||= []

        if question['question_type'] == 'missing_word_question'
          change_missing_word(question)
        end
        node.item(
                :ident => question['migration_id'],
                :title => question['name'].presence || question['question_name']
        ) do |item_node|
          item_node.itemmetadata do |meta_node|
            meta_node.qtimetadata do |qm_node|
              if for_cc
                meta_field(qm_node, 'cc_profile', CC_TYPE_PROFILES[question['question_type']])
                if question['question_type'] == 'essay_question'
                  meta_field(qm_node, 'qmd_computerscored', 'No')
                end
              else
                meta_field(qm_node, 'question_type', question['question_type'])
                meta_field(qm_node, 'points_possible', question['points_possible'])
                if question[:is_quiz_question]
                  meta_field(qm_node, 'assessment_question_identifierref', aq_mig_id)
                end
              end
            end
          end # meta data

          item_node.presentation do |pres_node|
            pres_node.material do |mat_node|
              html_mat_text(mat_node, "<div>#{question['question_text']}</div>", '')
            end
            presentation_options(pres_node, question)
          end # presentation

          unless ['text_only_question', 'file_upload_question'].include?(question['question_type'])
            item_node.resprocessing do |res_node|
              res_node.outcomes do |out_node|
                out_node.decvar(
                        :maxvalue => '100',
                        :minvalue => '0',
                        :varname => 'SCORE',
                        :vartype => 'Decimal'
                )
              end
              resprocessing(res_node, question)
            end # resprocessing

            itemproc_extenstion(node, question)

            item_feedback(item_node, 'general_fb', question, 'neutral_comments')
            item_feedback(item_node, 'correct_fb', question, 'correct_comments')
            item_feedback(item_node, 'general_incorrect_fb', question, 'incorrect_comments')
            question['answers'].each do |answer|
              item_feedback(item_node, "#{answer['id']}_fb", answer, 'comments')
            end
          end
        end # item
      end

      ## question response_str methods

      def presentation_options(node, question)
        if ['multiple_choice_question', 'true_false_question', 'multiple_answers_question'].member? question['question_type']
          multiple_choice_response_str(node, question)
        elsif ['short_answer_question', 'essay_question'].member? question['question_type']
          short_answer_response_str(node, question)
        elsif question['question_type'] == 'matching_question'
          matching_response_lid(node, question)
        elsif question['question_type'] == 'multiple_dropdowns_question'
          multiple_dropdowns_response_lid(node, question)
        elsif question['question_type'] == 'fill_in_multiple_blanks_question'
          multiple_dropdowns_response_lid(node, question)
        elsif question['question_type'] == 'calculated_question'
          calculated_response_str(node, question)
        elsif question['question_type'] == 'numerical_question'
          calculated_response_str(node, question)
        end
      end

      def multiple_choice_response_str(node, question)
        card = question['question_type'] == 'multiple_answers_question' ? 'Multiple' : 'Single'
        node.response_lid(
                :ident => "response1",
                :rcardinality => card
        ) do |r_node|
          r_node.render_choice do |rc_node|
            question['answers'].each do |answer|
              rc_node.response_label(
                      :ident => answer['id']
              ) do |rl_node|
                rl_node.material do |mat_node|
                  html_mat_text(mat_node, answer['html'], answer['text'])
                end # mat_node
              end # rl_node
            end
          end # rc_node
        end
      end

      def matching_response_lid(node, question)
        question['answers'].each do |answer|
          node.response_lid(:ident=>"response_#{answer['id']}") do |lid_node|
            lid_node.material do |mat_node|
              html_mat_text(mat_node, answer['html'], answer['text'])
            end

            lid_node.render_choice do |rc_node|
              next unless question['matches']
              question['matches'].each do |match|
                rc_node.response_label(:ident=>match['match_id']) do |r_node|
                  r_node.material do |mat_node|
                    mat_node.mattext match['text']
                  end
                end #r_node
              end
            end #rc_node
          end #lid_node
        end
      end

      def short_answer_response_str(node, question)
        node.response_str(
                :ident => "response1",
                :rcardinality => 'Single'
        ) do |r_node|
          r_node.render_fib {|n| n.response_label(:ident=>'answer1', :rshuffle=>'No')}
        end
      end

      def change_missing_word(question)
        # Convert this to a multiple_dropdowns_question then send it on its way
        question['question_text'] = "#{question['question_text'].gsub(%r{^<p>|</p>$}, '')} [drop1] #{question['text_after_answers'].gsub(%r{^<p>|</p>$}, '')}"
        question['answers'].each do |answer|
          answer['blank_id'] = 'drop1'
        end
        question['question_type'] = 'multiple_dropdowns_question'
      end

      def multiple_dropdowns_response_lid(node, question)
        groups = question['answers'].group_by{|a|a[:blank_id]}

        groups.each_pair do |id, answers|
          node.response_lid(:ident=>"response_#{id}") do |lid_node|
            lid_node.material do |mat_node|
              mat_node.mattext id
            end
            lid_node.render_choice do |rc_node|
              answers.each do |answer|
                rc_node.response_label(:ident=>answer['id']) do |r_node|
                  r_node.material do |mat_node|
                    html_mat_text(mat_node, answer['html'], answer['text'])
                  end
                end # r_node
              end
            end # rc_node
          end # lid_node
        end
      end

      def calculated_response_str(node, question)
        node.response_str(
                :ident => "response1",
                :rcardinality => 'Single'
        ) do |r_node|
          r_node.render_fib(:fibtype=>'Decimal') {|n| n.response_label(:ident=>'answer1')}
        end
      end

      ## question resprocessing methods

      def resprocessing(node, question)
        if !question['neutral_comments'].blank? || !question['neutral_comments_html'].blank?
          other_respcondition(node, 'Yes', 'general_fb')
        end

        unless ['matching_question', 'numerical_question'].member? question['question_type']
          answer_feedback_respconditions(node, question)
        end

        # question type specific resprocessing
        if ['multiple_choice_question', 'true_false_question'].member? question['question_type']
          multiple_choice_resprocessing(node, question)
        elsif question['question_type'] == 'multiple_answers_question'
          multiple_answers_resprocessing(node, question)
        elsif question['question_type'] == 'short_answer_question'
          short_answer_resprocessing(node, question)
        elsif question['question_type'] == 'essay_question'
          essay_resprocessing(node, question)
        elsif question['question_type'] == 'matching_question'
          matching_resprocessing(node, question)
        elsif question['question_type'] == 'multiple_dropdowns_question'
          multiple_dropdowns_resprocessing(node, question)
        elsif question['question_type'] == 'fill_in_multiple_blanks_question'
          multiple_dropdowns_resprocessing(node, question)
        elsif question['question_type'] == 'calculated_question'
          calculated_resprocessing(node, question)
        elsif question['question_type'] == 'numerical_question'
          numerical_resprocessing(node, question)
        end

        if (!question['incorrect_comments'].blank? || !question['incorrect_comments_html'].blank?) && !MULTI_ANSWER_TYPES.member?(question['question_type'])
          other_respcondition(node, 'Yes', 'general_incorrect_fb')
        end
      end

      def multiple_choice_resprocessing(node, question)
        correct_id = nil
        correct_answer = question['answers'].find{|a|a['weight'].to_i > 0}
        correct_id = correct_answer['id'] if correct_answer
        node.respcondition(:continue=>'No') do |res_node|
          res_node.conditionvar do |c_node|
            c_node.varequal correct_id, :respident=>"response1"
          end #c_node
          res_node.setvar '100', :action => 'Set', :varname => 'SCORE'
          correct_feedback_ref(res_node, question)
        end #res_node
      end

      def multiple_answers_resprocessing(node, question)
        node.respcondition(:continue=>'No') do |res_node|
          res_node.conditionvar do |c_node|
            c_node.and do |and_node|
              # The CC implementation guide says the 'and' isn't needed but it doesn't validate without it.
              question['answers'].each do |answer|
                if answer['weight'].to_i > 0
                  and_node.varequal answer['id'], :respident=>"response1"
                else
                  and_node.not do |not_node|
                    not_node.varequal answer['id'], :respident=>"response1"
                  end
                end
              end
            end
          end #c_node
          res_node.setvar '100', :action => 'Set', :varname => 'SCORE'
          correct_feedback_ref(res_node, question)
        end #res_node
      end

      def short_answer_resprocessing(node, question)
        node.respcondition(:continue=>'No') do |res_node|
          res_node.conditionvar do |c_node|
            question['answers'].each do |answer|
              c_node.varequal answer['text'], :respident=>"response1"
            end
          end #c_node
          res_node.setvar '100', :action => 'Set', :varname => 'SCORE'
          correct_feedback_ref(res_node, question)
        end #res_node
      end

      def numerical_resprocessing(node, question)
        question['answers'].each do |answer|
          node.respcondition(:continue=>'No') do |res_node|
            res_node.conditionvar do |c_node|
              if answer['exact']
                # exact answer
                c_node.or do |or_node|
                  exact = answer['exact'].to_f
                  or_node.varequal exact, :respident=>"response1"
                  unless answer['margin'].blank?
                    or_node.and do |and_node|
                      exact = BigDecimal.new(answer['exact'].to_s)
                      margin = BigDecimal.new(answer['margin'].to_s)
                      and_node.vargte((exact - margin).to_f, :respident=>"response1")
                      and_node.varlte((exact + margin).to_f, :respident=>"response1")
                    end
                  end
                end
              elsif answer["numerical_answer_type"] == "precision_answer"
                # this might be one of the worst hacks i've ever done
                c_node.or do |or_node|
                  approx = answer['approximate'].to_d
                  or_node.varequal approx, :respident=>"response1"

                  precision = answer['precision'].to_i
                  if precision > 0
                    # there's probably an easier way to do this but i wouldn't know what it is
                    sci_form = "%.#{precision - 1}E" % approx # e.g. 13.4 -> 1.340E+01 for precision 4
                    prefix, exp = sci_form.split("E")
                    range = "5E-#{precision}".to_d # 0.005
                    floor = "#{prefix.to_d - range}E#{exp}".to_d # 1.3395E+01
                    ceil = "#{prefix.to_d + range}E#{exp}".to_d # 1.3405E+01

                    or_node.and do |and_node|
                      and_node.vargt(floor, :respident=>"response1")
                      and_node.varlte(ceil, :respident=>"response1")
                    end
                  end
                end
              else
                # answer in range
                c_node.vargte(answer['start'], :respident=>"response1")
                c_node.varlte(answer['end'], :respident=>"response1")
              end
            end #c_node

            res_node.setvar '100', :action => 'Set', :varname => 'SCORE'
            res_node.displayfeedback(:feedbacktype=>'Response', :linkrefid=>"#{answer['id']}_fb") unless (answer['comments'].blank? && answer['comments_html'].blank?)
            correct_feedback_ref(res_node, question)
          end #res_node
        end
      end

      def essay_resprocessing(node, question)
        other_respcondition(node)
      end

      def matching_resprocessing(node, question)
        return nil unless question['answers'] && question['answers'].count > 0

        correct_points = 100.0 / question['answers'].count
        correct_points = "%.2f" % correct_points

        question['answers'].each do |answer|
          node.respcondition do |r_node|
            r_node.conditionvar do |c_node|
              c_node.varequal(answer['match_id'], :respident=>"response_#{answer['id']}")
            end
            r_node.setvar(correct_points, :varname => 'SCORE', :action => 'Add')
          end

          unless (answer['comments'].blank? && answer['comments_html'].blank?)
            node.respcondition do |r_node|
              r_node.conditionvar do |c_node|
                c_node.not do |n_node|
                  c_node.varequal(answer['match_id'], :respident=>"response_#{answer['id']}")
                end
              end
              r_node.displayfeedback(:feedbacktype=>'Response', :linkrefid=>"#{answer['id']}_fb")
            end
          end
        end
      end

      def multiple_dropdowns_resprocessing(node, question)
        groups = question['answers'].group_by{|a|a[:blank_id]}
        correct_points = 100.0 / groups.length
        correct_points = "%.2f" % correct_points

        groups.each_pair do |id, answers|
          if answer = answers.find{|a| a['weight'].to_i > 0}
            node.respcondition do |r_node|
              r_node.conditionvar do |c_node|
                c_node.varequal(answer['id'], :respident=>"response_#{id}")
              end
              r_node.setvar(correct_points, :varname => 'SCORE', :action => 'Add')
            end
          end
        end
      end

      def calculated_resprocessing(node, question)
        node.respcondition(:title=>'correct') do |r_node|
          r_node.conditionvar do |c_node|
            c_node.other
          end
          r_node.setvar(100, :varname => 'SCORE', :action => 'Set')
        end
        node.respcondition(:title=>'incorrect') do |r_node|
          r_node.conditionvar do |c_node|
            c_node.not {|n_node|n_node.other}
          end
          r_node.setvar(0, :varname => 'SCORE', :action => 'Set')
        end
      end

      # feedback helpers

      def answer_feedback_respconditions(node, question)
        question['answers'].each do |answer|
          unless (answer['comments'].blank? && answer['comments_html'].blank?)
            respident = 'response1'
            if MULTI_ANSWER_TYPES.member? question['question_type']
              respident = "response_#{answer['blank_id']}"
            end
            node.respcondition(:continue=>'Yes') do |res_node|
              res_node.conditionvar do |c_node|
                if question[:question_type] == 'short_answer_question'
                  c_node.varequal answer['text'], :respident=>respident
                else
                  c_node.varequal answer['id'], :respident=>respident
                end
              end #c_node
              node.displayfeedback(:feedbacktype=>'Response', :linkrefid=>"#{answer['id']}_fb")
            end
          end
        end
      end

      def other_respcondition(node, continue='No', feedback_ref=nil)
        node.respcondition(:continue=>continue) do |res_node|
          res_node.conditionvar do |c_node|
            c_node.other
          end #c_node
          res_node.displayfeedback(:feedbacktype=>'Response', :linkrefid=>feedback_ref) if feedback_ref
        end #res_node
      end

      def correct_feedback_ref(node, question)
        unless question['correct_comments'].blank? && question['correct_comments_html'].blank?
          node.displayfeedback(:feedbacktype=>'Response', :linkrefid=>'correct_fb')
        end
      end

      def item_feedback(node, id, question, key)
        return unless question[key].present? || question[key + "_html"].present?
        node.itemfeedback(:ident=>id) do |f_node|
          f_node.flow_mat do |flow_node|
            flow_node.material do |mat_node|
              html_mat_text(mat_node, question[key + "_html"], question[key])
            end
          end
        end
      end

      # Custom extensions

      def itemproc_extenstion(node, question)
        if question['question_type'] == 'calculated_question'
          calculated_extension(node, question)
        end
      end

      def calculated_extension(node, question)
        node.itemproc_extension do |ext_node|
          ext_node.calculated do |calc_node|
            calc_node.answer_tolerance question['answer_tolerance']

            calc_node.formulas(:decimal_places=>question['formula_decimal_places']) do |forms_node|
              question['formulas'].try(:each) do |f|
                forms_node.formula f['formula']
              end
            end

            calc_node.vars do |vars_node|
              question['variables'].try(:each) do |var|
                vars_node.var(:name=>var['name'], :scale=>var['scale']) do |var_node|
                  var_node.min var['min']
                  var_node.max var['max']
                end
              end
            end

            calc_node.var_sets do |sets_node|
              question['answers'].try(:each) do |answer|
                sets_node.var_set(:ident=>answer['id']) do |set_node|
                  answer['variables'].try(:each) do |var|
                    set_node.var(var['value'], :name=>var['name'])
                  end
                  set_node.answer answer[:answer]
                end
              end
            end
          end # calc_node
        end # ext_node
      end

      def html_mat_text(mat_node, html_val, text_val)
        if html_val.present?
          html = @html_exporter.html_content(html_val)
          mat_node.mattext html, :texttype => 'text/html'
        else
          mat_node.mattext text_val, :texttype => 'text/plain'
        end
      end

    end
  end
end
