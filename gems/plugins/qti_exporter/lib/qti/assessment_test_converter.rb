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

module Qti
class AssessmentTestConverter
  include Canvas::Migration::XMLHelper
  include HtmlHelper
  DEFAULT_POINTS_POSSIBLE = 1

  attr_reader :package_root, :identifier, :href, :interaction_type, :title, :quiz

  def initialize(manifest_node, base_dir, opts={})
    @log = Canvas::Migration::logger
    @manifest_node = manifest_node
    @package_root = PackageRoot.new(base_dir)
    @href = @package_root.item_path(@manifest_node['href'])
    @converted_questions = opts[:converted_questions]
    @opts = opts

    @quiz = {
            :questions=>[],
            :quiz_type=>nil,
            :question_count=>0
    }
  end

  def create_instructure_quiz
    begin
      # Get manifest data
      if md = @manifest_node.at_css("instructureMetadata")
        if item = get_node_att(md, 'instructureField[name=show_score]', 'value')
          @quiz[:show_score] = item =~ /true/i ? true : false
        end
        if item = get_node_att(md, 'instructureField[name=quiz_type]', 'value') || item = get_node_att(md, 'instructureField[name=bb8_assessment_type]', 'value')
          # known possible values: Self-assessment, Survey, Examination (practice is instructure default)
          # BB8: Test, Pool
          @quiz[:quiz_type] = "assignment" if item =~ /examination|test|quiz/i
          if item =~ /pool/i
            # if it's pool we don't need to make a quiz object.
            return nil
          end
        end
        if item = get_node_att(md, 'instructureField[name=which_attempt_to_keep]', 'value')
          # known possible values: Highest, First, Last (highest is instructure default)
          @quiz[:which_attempt_to_keep] = "keep_latest" if item =~ /last/i
        end
        if item = get_node_att(md, 'instructureField[name=max_score]', 'value')
          @quiz[:points_possible] = item
        end
        if item = get_node_att(md, 'instructureField[name=bb8_object_id]', 'value')
          @quiz[:alternate_migration_id] = item
        end
      end

      # Get the actual assessment file
      doc = Nokogiri::XML(File.open(@href))
      parse_quiz_data(doc)
      parse_instructure_metadata(doc)

      if @quiz[:quiz_type] == 'assignment'
        grading = {}
        grading[:migration_id] = @quiz[:migration_id]
        grading[:points_possible] = @quiz[:points_possible]
        grading[:weight] = nil
        grading[:due_date] = nil
        grading[:title] = @quiz[:title]
        grading[:grade_type] = 'numeric' if grading[:points_possible]
        @quiz[:grading] = grading
      end
    rescue
      @quiz[:qti_error] = "Error converting QTI quiz: #{$!}: #{$!.backtrace.join("\n\t")}"
      @log.error "Error converting QTI quiz: #{$!}: #{$!.backtrace.join("\n\t")}"
    end

    @quiz
  end

  def parse_instructure_metadata(doc)
    if meta = doc.at_css('instructureMetadata')
      if password = get_node_att(meta, 'instructureField[name=password]',  'value')
        @quiz[:access_code] = password
      end
      if id = get_node_att(meta, 'instructureField[name=assignment_identifierref]', 'value')
        @quiz[:assignment_migration_id] = id
      end

      if @opts[:flavor] == Qti::Flavors::D2L
        if intro = get_node_att(meta, 'instructureField[name=d2l_intro_message]', 'value')
          @quiz[:questions].unshift({:question_type => 'text_only_question', :question_text => intro, :migration_id => unique_local_id})
        end
        if html = get_node_att(meta, 'instructureField[name=assessment_rubric_html]', 'value')
          if node = (Nokogiri::HTML::DocumentFragment.parse(html) rescue nil)
            description = sanitize_html_string(node.text)
            @quiz[:description] = description if description.present?
          end
        end
      end
    end
  end

  def parse_quiz_data(doc)
    @quiz[:title] = @title || get_node_att(doc, 'assessmentTest', 'title')
    @quiz[:quiz_name] = @quiz[:title]
    @quiz[:migration_id] = get_node_att(doc, 'assessmentTest', 'identifier')
    if limit = doc.at_css('timeLimits')
      @quiz[:time_limit] = AssessmentTestConverter.parse_time_limit(limit['maxTime'])
    end
    if part = doc.at_css('testPart[identifier=BaseTestPart]') || doc.at_css('testPart')
      if control = part.at_css('itemSessionControl')
        if max = control['maxAttempts']
          max = -1 if max =~ /unlimited/i
          max = max.to_i
          # -1 means no limit in instructure, 0 means no limit in QTI
          @quiz[:allowed_attempts] = max >= 1 ? max : -1
        end
        if show = control['showSolution']
          show = show
          @quiz[:show_correct_answers] = show.downcase == "true" ? true : false
        end
      end

      process_section(part)
    else
      @quiz[:qti_error] = "Instructure doesn't support QTI importing from this source."
      @log.error "Attempted to convert QTI from non-supported source. (it wasn't run through the python conversion tool.)"
    end
  end

  def self.parse_time_limit(time_limit)
    limit = 0
    time_indicator = time_limit[0..0].downcase if time_limit.length > 0
    if time_indicator == 'd'
      limit = 24 * 60 * time_limit[1..-1].to_i
    elsif time_indicator == 'h'
      limit = 60 * time_limit[1..-1].to_i
    elsif time_indicator == 'm'
      limit = time_limit[1..-1].to_i
    else
      #instructure uses minutes, QTI uses seconds
      limit = time_limit.to_i / 60
    end

    limit
  end

  def process_section(section)
    group = nil
    questions_list = @quiz[:questions]

    if shuffle = get_node_att(section, 'ordering','shuffle')
      @quiz[:shuffle_answers] = true if shuffle =~ /true/i
    end
    if select = section.children.find {|child| child.name == "selection"}
      select = select['select'].to_i
      if select > 0
        group = {:questions=>[], :pick_count => select, :question_type => 'question_group', :title => section['title']}
        if weight = get_node_att(section, 'weight','value')
          group[:question_points] = convert_weight_to_points(weight)
        end
        if val = get_float_val(section, 'points_per_item')
          group[:question_points] = val
        end
        bank_refs = section.css('sourcebank_ref')
        if bank_refs.count > 1
          # multiple source banks for one section - duplicate the groups (see below)
          group[:question_bank_migration_ids] = bank_refs.map{|br| translate_bank_id(br.text)}
        elsif bank_refs.count == 1
          group[:question_bank_migration_id] = translate_bank_id(bank_refs.first.text)
        end
        if val = get_node_val(section, 'sourcebank_context')
          group[:question_bank_context] = val
        end
        if val = get_bool_val(section, 'sourcebank_is_external')
          group[:question_bank_is_external] = val
        end
        group[:migration_id] = section['identifier'] && section['identifier'] != "" ? section['identifier'] : unique_local_id
        questions_list = group[:questions]
      end
    end
    if section['visible'] and section['visible'] =~ /true/i
      if title = section['title']
        #Create an empty question with a title in it
        @quiz[:questions] << {:question_type => 'text_only_question', :question_text => title, :migration_id => unique_local_id}
      end
    end

    section.children.each do |child|
      if child.name == "assessmentSection"
        process_section(child)
      elsif child.name == "assessmentItemRef"
        process_question(child, questions_list)
      end
    end

    # if we didn't get a question weight, and all the questions have the same
    # points possible, use that as the group points possible per question
    if @converted_questions && select && select > 0 && group[:question_points].blank? && group[:questions].present?
      migration_ids = group[:questions].map { |q| q[:migration_id] }
      questions = @converted_questions.find_all { |q| migration_ids.include?(q[:migration_id]) }

      points = questions.first ? (questions.first[:points_possible] || 0) : 0
      if points > 0 && questions.size == group[:questions].size && questions.all? { |q| q[:points_possible] == points }
        group[:question_points] = points
      else
      end
    end

    group && group[:question_points] ||= DEFAULT_POINTS_POSSIBLE

    if group
      if group[:question_bank_migration_ids].present? && group[:questions].empty?
        # multiple source banks for one section - duplicate the groups for each bank
        group[:question_bank_migration_ids].each do |bank_ref_id|
          copy = group.deep_dup
          copy[:migration_id] = "#{group[:migration_id]}_#{bank_ref_id}"
          copy[:question_bank_migration_id] = bank_ref_id
          @quiz[:questions] << copy
        end
      elsif (!group[:questions].empty? || group[:question_bank_migration_id])
        @quiz[:questions] << group
      end
    end

    questions_list
  end

  def translate_bank_id(bank_id)
    if @opts[:alt_bank_id_map]
      @opts[:alt_bank_id_map][bank_id] || bank_id
    else
      bank_id
    end
  end

  def process_question(item_ref, questions_list)
    question = {:question_type => 'question_reference'}
    questions_list << question
    @quiz[:question_count] += 1
    # The colons are replaced with dashes in the conversion from QTI 1.2
    question[:migration_id] = item_ref['identifier'].gsub(/:/, '-')
    # D2L references questions by label instead of ident
    if @opts[:flavor] == Qti::Flavors::D2L && item_ref['label'].present?
      question[:migration_id] = item_ref['label']
    end
    if weight = get_node_att(item_ref, 'weight','value')
      question[:points_possible] = convert_weight_to_points(weight)
    end
  end

  # the weight from a webct system is represented as a float like 0.05,
  # but the point value for that float is actually 5. So if it's from
  # webct multiply it by 100
  def convert_weight_to_points(weight)
    begin
      weight = weight.to_f
      if @opts[:flavor] == Qti::Flavors::WEBCT
        weight = weight * 100
      end
    rescue
      weight = DEFAULT_POINTS_POSSIBLE
    end
    weight
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
end
end
