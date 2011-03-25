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
module Canvas::CC
  module QTI
    class QTIGenerator
      include Canvas::CC::CCHelper

      def initialize(manifest, resources_node)
        @manifest = manifest
        @resources_node = resources_node
        @course = manifest.course
        @export_dir = @manifest.export_dir
      end

      def self.generate_qti(manifest, resources_node)
        qti = QTI::QTIGenerator.new(manifest, resources_node)
        qti.generate
      end

      # Common Cartridge QTI doesn't support many of the quiz features needed
      # for canvas so this will export a CC-friendly QTI file and one that supports
      # everything needed for Canvas quizzes. In addition to the canvas-specific
      # QTI file there will be a Canvas-specific metadata file.
      def generate
        @course.quizzes.active.each do |quiz|
          cc_qti_migration_id = create_key(quiz)
          resource_dir = File.join(@export_dir, cc_qti_migration_id)
          FileUtils::mkdir_p resource_dir

          # Create the CC-friendly QTI
          cc_qti_rel_path = File.join(cc_qti_migration_id, ASSESSMENT_CC_QTI)
          cc_qti_path = File.join(resource_dir, ASSESSMENT_CC_QTI)
          File.open(cc_qti_path, 'w') do |file|
            generate_assessment(file, quiz, cc_qti_migration_id)
          end

          # Create the Canvas-specific QTI data
          qti_migration_id = create_key(quiz, 'canvas_')
          qti_rel_path = File.join(cc_qti_migration_id, ASSESSMENT_CANVAS_QTI)
          qti_path = File.join(resource_dir, ASSESSMENT_CANVAS_QTI)
          File.open(qti_path, 'w') do |file|
            generate_assessment(file, quiz, qti_migration_id, false)
          end

          # Create the canvas metadata
          inst_file_name = ASSESSMENT_INSTRUCTIONS
          inst_rel_path = File.join(cc_qti_migration_id, inst_file_name)
          inst_path = File.join(resource_dir, inst_file_name)
          File.open(inst_path, 'w') do |file|
            file << CCHelper.html_page(quiz.description || '', "Quiz: " + quiz.title, @course, @manifest.exporter.user)
          end

          @resources_node.resource(
                  :identifier => cc_qti_migration_id,
                  "type" => ASSESSMENT_TYPE
          ) do |res|
            res.file(:href=>cc_qti_rel_path)
            res.dependency(:identifierref=>qti_migration_id)
          end
          @resources_node.resource(
                  :identifier => qti_migration_id,
                  :type => LOR,
                  :href => qti_rel_path
          ) do |res|
            res.file(:href=>qti_rel_path)
            res.file(:href=>inst_rel_path)
          end
        end
      end
      
      def generate_assessment(file, quiz, migration_id, for_cc=true)
        link_doc = Builder::XmlMarkup.new(:target=>file, :indent=>2)
        link_doc.instruct!
        
        xsd_uri = for_cc ? 'http://www.imsglobal.org/profile/cc/ccv1p0/derived_schema/domainProfile_4/ims_qtiasiv1p2_localised.xsd' : 'http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd'
  
        link_doc.questestinterop("xmlns" => "http://www.imsglobal.org/xsd/ims_qtiasiv1p2",
                        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                        "xsi:schemaLocation"=> "http://www.imsglobal.org/xsd/ims_qtiasiv1p2 #{xsd_uri}"
        ) do |qti_node|
          qti_node.assessment(
                  :ident => migration_id,
                  :title => quiz.title 
          ) do |asmnt_node|
            asmnt_node.qtimetadata do |meta_node|
              if for_cc
                # Common Cartridge specific properties
                meta_field(meta_node, 'cc_profile', 'cc.exam.v0p1')
                meta_field(meta_node, 'qmd_assessmenttype', 'Examination')
                meta_field(meta_node, 'qmd_scoretype', 'Percentage')
              else
                # Canvas properties
                meta_field(meta_node, 'canvas_lock_at', ims_datetime(quiz.lock_at)) if quiz.lock_at
                meta_field(meta_node, 'canvas_unlock_at', ims_datetime(quiz.unlock_at)) if quiz.unlock_at
                meta_field(meta_node, 'canvas_due_at', ims_datetime(quiz.due_at)) if quiz.due_at
                meta_field(meta_node, 'canvas_shuffle_answers', quiz.shuffle_answers.to_s)
                meta_field(meta_node, 'canvas_scoring_policy', quiz.scoring_policy)
                meta_field(meta_node, 'canvas_hide_results', quiz.hide_results) unless quiz.hide_results.nil?
                meta_field(meta_node, 'canvas_quiz_type', quiz.quiz_type)
                meta_field(meta_node, 'canvas_points_possible', quiz.points_possible)
                meta_field(meta_node, 'canvas_require_lockdown_browser', quiz.require_lockdown_browser) unless quiz.require_lockdown_browser.nil?
                meta_field(meta_node, 'canvas_access_code', quiz.access_code) unless quiz.access_code.blank?
                meta_field(meta_node, 'canvas_ip_filter', quiz.ip_filter) unless quiz.ip_filter.blank?
                meta_field(meta_node, 'canvas_show_correct_answers', quiz.show_correct_answers)
                meta_field(meta_node, 'canvas_anonymous_submissions', quiz.anonymous_submissions)
                meta_field(meta_node, 'canvas_could_be_locked', quiz.could_be_locked) unless quiz.could_be_locked.nil?
                meta_field(meta_node, 'assignment_identifierref', create_key(quiz.assignment)) if quiz.assignment
                if quiz.assignment_group_id
                  ag = @course.assignment_groups.find(quiz.assignment_group_id)
                  meta_field(meta_node, 'assignment_group_identifierref', create_key(ag))
                end
              end
              
              # Properties for both
              meta_field(meta_node, 'qmd_timelimit', quiz.time_limit) if quiz.time_limit
              allowed = quiz.allowed_attempts == -1 ? 'unlimited' : quiz.allowed_attempts
              meta_field(meta_node, 'cc_maxattempts', allowed)
            end # meta_node
            
            asmnt_node.section(
                    :ident => "root_section"
            ) do |section_node|
              quiz.root_entries.each do |item|
                if item[:answers]
                  if for_cc
                    add_cc_question(section_node, item)
                  else
                    add_question(section_node, item)
                  end
                elsif item[:questions] # It's a QuizGroup
                  if for_cc
                    add_cc_group(section_node, item)
                  else
                    add_group(section_node, item)
                  end
                end
              end
            end # section_node
          end # assessment_node
        end # qti node
      end
      
      def meta_field(node, label, entry)
        node.qtimetadatafield do |meta_node|
          meta_node.fieldlabel label
          meta_node.fieldentry entry
        end
      end
      
      # if the question is a supported CC type it will be added
      # it it's not supported it's just skipped
      # returns boolean - whether the question was added
      def add_cc_question(node, question)
        node.item(
                :ident => question['id'],
                :title => question['name']
        ) do |item_node|
          item_node.comment! "todo: make #{question['question_type']} questions"
        end
        
        true
      end
      
      # Common Cartridge only allows for one section in an assessment
      # that means that you can't have any groups. So we just choose
      # however many (supported) questions there are supposed to be
      # in the group and add those.
      def add_cc_group(node, group)
        pick_count = group['pick_count'].to_i
        chosen = 0
        if group[:assessment_question_bank_id]
          if bank = @course.assessment_question_banks.find(group[:assessment_question_bank_id])
            bank.assessment_questions.each do |question|
              # try adding questions until the pick count is reached
              chosen += 1 if add_cc_question(node, question)
              break if chosen == pick_count
            end
          end
        else
          group[:questions].each do |question|
            # try adding questions until the pick count is reached
            chosen += 1 if add_cc_question(node, question)
            break if chosen == pick_count
          end
        end
      end
      
      def add_question(node, question)
        node.item(
                :ident => question['id'],
                :title => question['name']
        ) do |item_node|
          item_node.comment! "todo: make #{question['question_type']} questions"
        end
      end
      
      def add_group(node, group)
        id = create_key(group['id']) 
        node.section(
                :ident => id,
                :title => group['name']
        ) do |section_node|
          section_node.selection_ordering do |so_node|
            section_node.selection do |sel_node|
              if group[:assessment_question_bank_id]
                if bank = @course.assessment_question_banks.find(group[:assessment_question_bank_id])
                  sel_node.sourcebank_ref create_key(bank)
                end
              end
              sel_node.selection_number group['pick_count']
              sel_node.selection_extension do |ext_node|
                ext_node.points_per_item group['question_points']
              end
            end
          end
          
          unless group[:assessment_question_bank_id]
            group[:questions].each do |question|
              add_question(section_node, question)
            end
          end
        end # section node
      end

    end
  end
end
