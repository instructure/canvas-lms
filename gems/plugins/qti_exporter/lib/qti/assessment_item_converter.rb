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

require 'nokogiri'
require 'sanitize'

module Qti
class AssessmentItemConverter
  include Canvas::Migration::XMLHelper
  include HtmlHelper

  DEFAULT_CORRECT_WEIGHT = 100
  DEFAULT_INCORRECT_WEIGHT = 0
  DEFAULT_POINTS_POSSIBLE = 1
  UNSUPPORTED_TYPES = ['File Upload', 'Hot Spot', 'Quiz Bowl', 'WCT_JumbledSentence']

  attr_reader :package_root, :identifier, :href, :interaction_type, :title, :question

  def initialize(opts)
    @log = Canvas::Migration::logger
    reset_local_ids
    @manifest_node = opts[:manifest_node]
    @migration_type = opts[:interaction_type]
    @doc = nil
    @flavor = opts[:flavor]
    @opts = opts
    if @path_map = opts[:file_path_map]
      @sorted_paths = opts[:sorted_file_paths]
      @sorted_paths ||= @path_map.keys.sort_by { |v| v.length }
    end

    if @manifest_node
      @package_root = PackageRoot.new(opts[:base_dir])
      @identifier = @manifest_node['identifier']
      @href = @package_root.item_path(@manifest_node['href'])
      if title = @manifest_node.at_css('title langstring') || title = @manifest_node.at_css('xmlns|title xmlns|langstring', 'xmlns' => Qti::Converter::IMS_MD)
        @title = title.text
      end
    else
      @qti_data = opts[:qti_data]
    end

    @question = {:answers=>[],
                 :correct_comments=>"",
                 :incorrect_comments=>"",
                 :question_text=>""}
  end

  #This should be implemented in the children classes to do the type-specific parsing
  def parse_question_data
    @log.error "No question type used..."
    raise "No question type used when trying to parse a qti question"
  end

  def create_doc
    create_xml_doc
  end

  def create_xml_doc
    if @manifest_node
      @doc = Nokogiri::XML(File.open(@href))
    else
      @doc = Nokogiri::XML(@qti_data)
    end
  end

  EXCLUDED_QUESTION_TEXT_CLASSES = ["RESPONSE_BLOCK", "RIGHT_MATCH_BLOCK"]

  def create_instructure_question
    begin
      create_doc
      @question[:question_name] = @title || get_node_att(@doc, 'assessmentItem', 'title')
      # The colons are replaced with dashes in the conversion from QTI 1.2
      @question[:migration_id] = get_node_att(@doc, 'assessmentItem', 'identifier')
      @question[:migration_id] = @question[:migration_id].gsub(/:/, '-').gsub('identifier=', '') if @question[:migration_id]

      if @flavor == Qti::Flavors::D2L
        # In D2L-generated QTI the assessments reference the items by the label instead of the identifier
        # also, the identifier is not always unique, so we use the label as the migration id
        @question[:migration_id] = get_node_att(@doc, 'assessmentItem', 'label')
      end

      if @type == 'text_entry_interaction'
        @doc.css('textEntryInteraction').each do |node|
          node.inner_html = "[#{node['responseIdentifier']}]"
        end
      end

      parse_instructure_metadata

      selectors = ['itemBody > div', 'itemBody > p']
      type = @opts[:custom_type] || @migration_type || @type
      unless ['fill_in_multiple_blanks_question', 'canvas_matching', 'matching_question',
              'multiple_dropdowns_question', 'respondus_matching'].include?(type)
        selectors << 'itemBody choiceInteraction > prompt'
        selectors << 'itemBody > extendedTextInteraction > prompt'
      end

      text_nodes = @doc.css(selectors.join(','))
      text_nodes = text_nodes.reject{|node| node.inner_html.strip.empty? ||
        EXCLUDED_QUESTION_TEXT_CLASSES.any?{|c| c.casecmp(node['class'].to_s) == 0} ||
        node.at_css('choiceInteraction') || node.at_css('associateInteraction')}

      if text_nodes.length > 0
        @question[:question_text] = ''
        text_nodes.each_with_index do |node, i|
          @question[:question_text] += "\n<br/>\n" if i > 0
          if ['html', 'text'].include?(node['class'])
            @question[:question_text] += sanitize_html_string(node.text)
          else
            @question[:question_text] += sanitize_html!(node)
          end
        end
      elsif @doc.at_css('itemBody associateInteraction prompt')
        @question[:question_text] = "" # apparently they deliberately had a blank question?
      elsif text = @doc.at_css('itemBody div:first-child') || @doc.at_css('itemBody p:first-child') || @doc.at_css('itemBody div') || @doc.at_css('itemBody p')
        @question[:question_text] = sanitize_html!(text)
      elsif @doc.at_css('itemBody')
        if text = @doc.at_css('itemBody').children.find{|c|c.text.strip != ''}
          @question[:question_text] = sanitize_html_string(text.text)
        end
      end

      if @migration_type and UNSUPPORTED_TYPES.member?(@migration_type)
        @question[:question_type] = @migration_type
        @question[:unsupported] = true
      elsif !%w(text_only_question file_upload_question).include?(@migration_type)
        self.parse_question_data
      else
        @question[:question_type] ||= @migration_type
      end
    rescue => e
      message = "There was an error exporting an assessment question"
      @question[:qti_error] = "#{message} - #{e}"
      @question[:question_type] = "Error"
      @log.error "#{e}: #{e.backtrace}"
    end

    @question[:points_possible] ||= AssessmentItemConverter::DEFAULT_POINTS_POSSIBLE
    @question
  end

  QUESTION_TYPE_MAPPING = {
    /matching/i => 'matching_question',
    /text\s?information/i => 'text_only_question',
    /image/i => 'text_only_question',
    'trueFalse' => 'true_false_question',
    /true\/false/i => 'true_false_question',
    'multiple_dropdowns' => 'multiple_dropdowns_question'
  }

  def parse_instructure_metadata
    if meta = @doc.at_css('instructureMetadata')
      if bank =  get_node_att(meta, 'instructureField[name=question_bank]',  'value')
        @question[:question_bank_name] = bank
      end
      if bank = get_node_att(meta, 'instructureField[name=question_bank_iden]', 'value')
        @question[:question_bank_id] = bank
        if bb_bank = get_node_att(meta, 'instructureField[name=bb_question_bank_iden]', 'value')
          @question[:bb_question_bank_id] = bb_bank
        end
      end
      if score = get_node_att(meta, 'instructureField[name=max_score]', 'value')
        @question[:points_possible] = [score.to_f, 0.0].max
      end
      if score = get_node_att(meta, 'instructureField[name=points_possible]', 'value')
        @question[:points_possible] = [score.to_f, 0.0].max
      end
      if ref = get_node_att(meta, 'instructureField[name=assessment_question_identifierref]', 'value')
        @question[:assessment_question_migration_id] = ref
      end
      if get_node_att(meta, 'instructureField[name=cc_profile]', 'value') == 'cc.pattern_match.v0p1'
        @question[:is_cc_pattern_match] = true
      end
      if type =  get_node_att(meta, 'instructureField[name=bb_question_type]', 'value')
        @migration_type = type
        case @migration_type
          when 'True/False'
            @question[:question_type] = 'true_false_question'
          when 'Short Response'
            @question[:question_type] = 'essay_question'
          when 'Fill in the Blank Plus'
            @question[:question_type] = 'fill_in_multiple_blanks_question'
          when 'WCT_FillInTheBlank'
            @question[:question_type] = 'fill_in_multiple_blanks_question'
            @question[:is_vista_fib] = true
          when 'WCT_ShortAnswer'
            if @doc.css("responseDeclaration[baseType=\"string\"]").count > 1
              @question[:question_type] = 'fill_in_multiple_blanks_question'
              @question[:is_vista_fib] = true
            end
          when 'Jumbled Sentence'
            @question[:question_type] = 'multiple_dropdowns_question'
          when 'Essay'
            @question[:question_type] = 'essay_question'
        end
      elsif type =  get_node_att(meta, 'instructureField[name=question_type]', 'value')
        @migration_type = type
        QUESTION_TYPE_MAPPING.each do |k,v|
          @migration_type = v if k === @migration_type
        end
        if AssessmentQuestion::ALL_QUESTION_TYPES.member?(@migration_type)
          @question[:question_type] = @migration_type
        end
      end
    end
  end

  def unique_local_id
    @@ids ||= {}
    id = rand(100_000)
    while @@ids[id]
      id = rand(100_000)
    end
    @@ids[id] = true
    id
  end

  def reset_local_ids
    @@ids = {}
  end

  def get_feedback
    @doc.search('modalFeedback').each do |f|
      id = f['identifier']
      if id =~ /wrong|incorrect|(_IC$)/i
        extract_feedback!(@question, :incorrect_comments, f)
      elsif id =~ /correct|(_C$)/i
        if f.at_css('div.solution')
          @question[:example_solution] = clear_html(f.text.strip.gsub(/\s+/, " "))
        else
          extract_feedback!(@question, :correct_comments, f)
        end
      elsif id =~ /solution/i
        @question[:example_solution] = clear_html(f.text.strip.gsub(/\s+/, " "))
      elsif (@flavor == Qti::Flavors::D2L && f.text.present?) || id =~ /general_|_all/i
        extract_feedback!(@question, :neutral_comments, f)
      elsif id =~ /feedback_(\d*)_fb/i
        if answer = @question[:answers].find{|a|a[:migration_id]== "RESPONSE_#{$1}"}
          extract_feedback!(answer, :comments, f)
        end
      end
    end
  end

  def extract_feedback!(hash, field, node)
    text, html = detect_html(node)
    hash[field] = text
    if html
      hash["#{field}_html".to_sym] = html
    end
  end

  KNOWN_META_CLASSES = ['FORMATTED_TEXT_BLOCK', 'flow_1']
  def has_known_meta_class(node)
    return false unless node.attributes['class']
    KNOWN_META_CLASSES.member?(node.attributes['class'].value)
  end

  def self.get_interaction_type(manifest_node)
    manifest_node.at_css('interactionType') ||
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_1_URL) ||
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_0_URL) ||
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_1_ITEM_URL) ||
      manifest_node.at_css('xmlns|interactionType', 'xmlns' => Qti::Converter::QTI_2_0_ITEM_URL)
  end

  def self.create_instructure_question(opts)
    extend Canvas::Migration::XMLHelper
    q = nil
    manifest_node = opts[:manifest_node]

    if manifest_node
      if type = get_interaction_type(manifest_node)
        opts[:interaction_type] ||= type.text.downcase
      end
      if type = get_node_att(manifest_node,'instructureMetadata instructureField[name=bb_question_type]', 'value')
        opts[:custom_type] ||= type.downcase
      end
      if type = get_node_att(manifest_node,'instructureMetadata instructureField[name=question_type]', 'value')
        type = type.downcase
        opts[:custom_type] ||= type
        if type == 'matching_question'
          opts[:interaction_type] = 'choiceinteraction'
          opts[:custom_type] = 'canvas_matching'
        elsif type == 'matching'
          opts[:custom_type] = 'respondus_matching'
        elsif type =~ /fillInMultiple|fill_in_multiple_blanks_question|fill in the blanks/i
          opts[:interaction_type] = 'fill_in_multiple_blanks_question'
        elsif type == 'multiple_dropdowns_question'
          opts[:interaction_type] = 'multiple_dropdowns_question'
        else
          opts[:custom_type] = type
        end
      end
    end

    unless opts[:interaction_type]
      guesser = QuestionTypeEducatedGuesser.new(opts)
      opts[:interaction_type], opts[:custom_type] = guesser.educatedly_guess_type
    end

    case opts[:interaction_type]
      when /choiceinteraction|multiple_choice_question|multiple_answers_question|true_false_question|stupid_likert_scale_question/i
        if opts[:custom_type] and opts[:custom_type] == "matching"
          q = AssociateInteraction.new(opts)
        elsif opts[:custom_type] && opts[:custom_type] =~ /respondus_matching|canvas_matching/
          q = AssociateInteraction.new(opts)
        else
          q = ChoiceInteraction.new(opts)
        end
      when /associateinteraction|matching_question|matchinteraction/i
        q = AssociateInteraction.new(opts)
      when /extendedtextinteraction|extendedtextentryinteraction|textinteraction|essay_question|short_answer_question/i
        if opts[:custom_type] and opts[:custom_type] =~ /calculated/i
          q = CalculatedInteraction.new(opts)
        elsif opts[:custom_type] and opts[:custom_type] =~ /numeric|numerical_question/
          q = NumericInteraction.new(opts)
        else
          q = ExtendedTextInteraction.new(opts)
        end
      when /orderinteraction|ordering_question/i
        q = OrderInteraction.new(opts)
      when /fill_in_multiple_blanks_question|multiple_dropdowns_question/i
        q = FillInTheBlank.new(opts)
      when /textentryinteraction/i
        q = FillInTheBlank.new(opts)
      when nil
        q = AssessmentItemConverter.new(opts)
      else
        Canvas::Migration::logger.warn "Unknown QTI question type: #{opts[:interaction_type]}"
        q = AssessmentItemConverter.new(opts)
    end

    q.create_instructure_question if q
  end

  # Sets the actual feedback values and clears the feedback ids
  def attach_feedback_values(answers)
    feedback_hash = {}
    @doc.search('modalFeedback').each do |feedback|
      id = feedback['identifier']
      node = feedback.at_css('p') || feedback.at_css('div')
      feedback_hash[id] = node if node
    end

    #clear extra entries
    @question.delete :feedback_id
    answers.each do |answer|
      if feedback_hash.has_key? answer[:feedback_id]
        extract_feedback!(answer, :comments, feedback_hash[answer[:feedback_id]])
      end
      answer.delete :feedback_id
    end
  end

  # pulls the feedback id from the condition
  def get_feedback_id(cond)
    id = nil

    if feedback = cond.at_css('setOutcomeValue[identifier=FEEDBACK]')
      if feedback.at_css('variable[identifier=FEEDBACK]')
        if feedback = feedback.at_css('baseValue[baseType=identifier]')
          id = feedback.text.strip
        end
      end
    end
    # Sometimes individual answers are assigned general feedback, don't return
    # the identifier if that's the case
    id =~ /general_|_all|wrong|incorrect|correct|(_IC$)|(_C$)/i ? nil : id
  end

end
end
