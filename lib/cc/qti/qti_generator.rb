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
module CC
  module QTI
    class QTIGenerator
      include CC::CCHelper
      include QTIItems
      delegate :add_error, :export_object?, :add_exported_asset, :create_key, :to => :@manifest

      def initialize(manifest, resources_node, html_exporter)
        @manifest = manifest
        @user = manifest.user
        @resources_node = resources_node
        @course = manifest.course
        @export_dir = @manifest.export_dir
        @html_exporter = html_exporter
      end

      def self.generate_qti(*args)
        qti = QTI::QTIGenerator.new(*args)
        qti.generate
      end

      # Common Cartridge QTI doesn't support many of the quiz features needed
      # for canvas so this will export a CC-friendly QTI file and one that supports
      # everything needed for Canvas quizzes. In addition to the canvas-specific
      # QTI file there will be a Canvas-specific metadata file.
      def generate
        non_cc_folder = File.join(@export_dir, ASSESSMENT_NON_CC_FOLDER)
        FileUtils::mkdir_p non_cc_folder

        @course.assessment_question_banks.active.each do |bank|
          next unless export_object?(bank)
          begin
            generate_question_bank(bank)
          rescue
            title = if bank
                      bank.title
                    else
                      I18n.t('unknown_question_bank', "Unknown question bank")
                    end

            add_error(I18n.t('course_exports.errors.question_bank', "The question bank \"%{title}\" failed to export", :title => title), $!)
          end
        end

        Quizzes::ScopedToUser.new(@course, @user, @course.quizzes.active).scope.each do |quiz|
          next unless export_object?(quiz) || export_object?(quiz.assignment)

          title = if quiz
                    quiz.title
                  else
                    I18n.t('unknown_quiz', "Unknown quiz")
                  end

          if quiz.assignment && !quiz.assignment.can_copy?(@user)
            add_error(I18n.t('course_exports.errors.quiz_is_locked', "The quiz \"%{title}\" could not be copied because it is locked.", :title => title))
            next
          end

          begin
            generate_quiz(quiz)
          rescue
            add_error(I18n.t('course_exports.errors.quiz', "The quiz \"%{title}\" failed to export", :title => title), $!)
          end
        end
      end

      def generate_quiz(quiz, for_cc=true)
        add_exported_asset(quiz)

        cc_qti_migration_id = create_key(quiz)
        resource_dir = File.join(@export_dir, cc_qti_migration_id)
        FileUtils::mkdir_p resource_dir

        # Create the CC-friendly QTI
        file_name = for_cc ? ASSESSMENT_CC_QTI : "#{cc_qti_migration_id}.xml"
        cc_qti_rel_path = File.join(cc_qti_migration_id, file_name)
        cc_qti_path = File.join(@export_dir, cc_qti_rel_path)

        File.open(cc_qti_path, 'w') do |file|
          doc = Builder::XmlMarkup.new(:target=>file, :indent=>2)
          generate_assessment(doc, quiz, cc_qti_migration_id, for_cc)
        end

        if for_cc
          # Create the Canvas-specific QTI data
          canvas_qti_rel_path = File.join(ASSESSMENT_NON_CC_FOLDER, cc_qti_migration_id + QTI_EXTENSION)
          canvas_qti_path = File.join(@export_dir, canvas_qti_rel_path)
          File.open(canvas_qti_path, 'w') do |file|
            doc = Builder::XmlMarkup.new(:target=>file, :indent=>2)
            generate_assessment(doc, quiz, cc_qti_migration_id, false)
          end
        end

        # Create the canvas metadata
        alt_migration_id = create_key(quiz, 'canvas_')
        meta_rel_path = File.join(cc_qti_migration_id, ASSESSMENT_META)
        meta_path = File.join(resource_dir, ASSESSMENT_META)
        File.open(meta_path, 'w') do |file|
          doc = Builder::XmlMarkup.new(:target=>file, :indent=>2)
          generate_assessment_meta(doc, quiz, cc_qti_migration_id)
        end

        @resources_node.resource(
                :identifier => cc_qti_migration_id,
                "type" => for_cc ? ASSESSMENT_TYPE : QTI_ASSESSMENT_TYPE
        ) do |res|
          res.file(:href=>cc_qti_rel_path)
          res.dependency(:identifierref=>alt_migration_id)
        end

        @resources_node.resource(
                :identifier => alt_migration_id,
                :type => LOR,
                :href => meta_rel_path
        ) do |res|
          res.file(:href=>meta_rel_path)
          res.file(:href=>canvas_qti_rel_path) if for_cc
        end
      end

      def generate_qti_only
        FileUtils::mkdir_p @export_dir

        non_cc_folder = File.join(@export_dir, ASSESSMENT_NON_CC_FOLDER)
        FileUtils::mkdir_p non_cc_folder

        @course.quizzes.active.each do |quiz|
          next unless export_object?(quiz)
          begin
            generate_quiz(quiz, false)
          rescue
            title = quiz.title rescue I18n.t('unknown_quiz', "Unknown quiz")
            add_error(I18n.t('course_exports.errors.quiz', "The quiz \"%{title}\" failed to export", :title => title), $!)
          end
        end
      end

      def generate_question_bank(bank)
        add_exported_asset(bank)

        bank_mig_id = create_key(bank)

        rel_path = File.join(ASSESSMENT_NON_CC_FOLDER, bank_mig_id + QTI_EXTENSION)
        full_path = File.join(@export_dir, rel_path)
        File.open(full_path, 'w') do |file|
          doc = Builder::XmlMarkup.new(:target=>file, :indent=>2)
          generate_bank(doc, bank, bank_mig_id)
        end

        @resources_node.resource(
                :identifier => bank_mig_id,
                :type => LOR,
                :href => rel_path
        ) do |res|
          res.file(:href=>rel_path)
        end
      end

      def generate_assessment_meta(doc, quiz, migration_id)
        doc.instruct!
        doc.quiz("identifier" => migration_id,
                        "xmlns" => CCHelper::CANVAS_NAMESPACE,
                        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                        "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
        ) do |q_node|
          q_node.title quiz.title
          q_node.description @html_exporter.html_content(quiz.description || '')
          q_node.lock_at ims_datetime(quiz.lock_at) if quiz.lock_at
          q_node.unlock_at ims_datetime(quiz.unlock_at) if quiz.unlock_at
          q_node.due_at ims_datetime(quiz.due_at) if quiz.due_at
          q_node.shuffle_answers quiz.shuffle_answers unless quiz.shuffle_answers.nil?
          q_node.scoring_policy quiz.scoring_policy
          q_node.hide_results quiz.hide_results unless quiz.hide_results.nil?
          q_node.quiz_type quiz.quiz_type
          q_node.points_possible quiz.points_possible
          q_node.require_lockdown_browser quiz.require_lockdown_browser unless quiz.require_lockdown_browser.nil?
          q_node.require_lockdown_browser_for_results quiz.require_lockdown_browser_for_results unless quiz.require_lockdown_browser_for_results.nil?
          q_node.require_lockdown_browser_monitor quiz.require_lockdown_browser_monitor unless quiz.require_lockdown_browser_monitor.nil?
          q_node.lockdown_browser_monitor_data quiz.lockdown_browser_monitor_data
          q_node.access_code quiz.access_code unless quiz.access_code.blank?
          q_node.ip_filter quiz.ip_filter unless quiz.ip_filter.blank?
          q_node.show_correct_answers quiz.show_correct_answers unless quiz.show_correct_answers.nil?
          q_node.show_correct_answers_at quiz.show_correct_answers_at unless quiz.show_correct_answers_at.nil?
          q_node.hide_correct_answers_at quiz.hide_correct_answers_at unless quiz.hide_correct_answers_at.nil?
          q_node.anonymous_submissions quiz.anonymous_submissions unless quiz.anonymous_submissions.nil?
          q_node.could_be_locked quiz.could_be_locked unless quiz.could_be_locked.nil?
          q_node.time_limit quiz.time_limit unless quiz.time_limit.nil?
          q_node.allowed_attempts quiz.allowed_attempts unless quiz.allowed_attempts.nil?
          q_node.one_question_at_a_time quiz.one_question_at_a_time?
          q_node.cant_go_back quiz.cant_go_back?
          q_node.available quiz.available?
          q_node.one_time_results quiz.one_time_results?
          q_node.show_correct_answers_last_attempt quiz.show_correct_answers_last_attempt?
          q_node.only_visible_to_overrides quiz.only_visible_to_overrides?
          q_node.module_locked quiz.locked_by_module_item?(@user, deep_check_if_needed: true).present?
          if quiz.assignment && !quiz.assignment.deleted?
            assignment_migration_id = create_key(quiz.assignment)
            doc.assignment(:identifier=>assignment_migration_id) do |a|
              AssignmentResources.create_canvas_assignment(a, quiz.assignment, @manifest)
            end
          end
          if quiz.assignment_group_id
            ag = @course.assignment_groups.find(quiz.assignment_group_id)
            q_node.assignment_group_identifierref create_key(ag)
          end
          q_node.assignment_overrides do |ao_node|
            quiz.assignment_overrides.active.where(set_type: 'Noop').each do |o|
              override_attrs = o.slice(:set_type, :set_id, :title)
              AssignmentOverride.overridden_dates.each do |field|
                next unless o.send("#{field}_overridden")
                override_attrs[field] = o[field]
              end
              ao_node.override(override_attrs)
            end
          end
        end
      end

      def generate_assessment(doc, quiz, migration_id, for_cc=true)
        doc.instruct!

        xsd_uri = for_cc ? 'http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_qtiasiv1p2p1_v1p0.xsd' : 'http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd'

        doc.questestinterop("xmlns" => "http://www.imsglobal.org/xsd/ims_qtiasiv1p2",
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
              end
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
                    add_quiz_question(section_node, item)
                  end
                elsif item[:questions] # It's a Quizzes::QuizGroup
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

      def generate_bank(doc, bank, migration_id)
        doc.instruct!
        doc.questestinterop("xmlns" => "http://www.imsglobal.org/xsd/ims_qtiasiv1p2",
                        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                        "xsi:schemaLocation"=> "http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd"
        ) do |qti_node|
          qti_node.objectbank(
                  :ident => migration_id
          ) do |bank_node|

            bank_node.qtimetadata do |meta_node|
              meta_field(meta_node, 'bank_title', bank.title)
            end # meta_node

            bank.assessment_questions.active.each do |aq|
              add_question(bank_node, aq.data.with_indifferent_access)
            end

          end # bank_node
        end # qti node
      end

      def meta_field(node, label, entry)
        node.qtimetadatafield do |meta_node|
          meta_node.fieldlabel label
          meta_node.fieldentry entry
        end
      end

      # Common Cartridge only allows for one section in an assessment
      # that means that you can't have any groups. So we just choose
      # however many (supported) questions there are supposed to be
      # in the group and add those.
      def add_cc_group(node, group)
        pick_count = group['pick_count'].to_i
        chosen = 0
        if group[:assessment_question_bank_id]
          if bank = @course.assessment_question_banks.where(id: group[:assessment_question_bank_id]).first
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

      def add_group(node, group)
        id = create_key("quizzes/quiz_group_#{group['id']}")
        node.section(
                :ident => id,
                :title => group['name']
        ) do |section_node|
          section_node.selection_ordering do |so_node|
            so_node.selection do |sel_node|
              is_external = false
              bank = nil

              if group[:assessment_question_bank_id]
                if bank = @course.assessment_question_banks.where(id: group[:assessment_question_bank_id]).first
                  sel_node.sourcebank_ref create_key(bank)
                elsif bank = AssessmentQuestionBank.where(id: group[:assessment_question_bank_id]).first
                  sel_node.sourcebank_ref bank.id
                  is_external = true
                end
              end
              sel_node.selection_number group['pick_count']
              sel_node.selection_extension do |ext_node|
                ext_node.points_per_item group['question_points']
                if is_external && bank && bank.context
                  sel_node.sourcebank_context bank.context.asset_string
                  sel_node.sourcebank_is_external 'true'
                end
              end
            end
          end

          unless group[:assessment_question_bank_id]
            group[:questions].each do |question|
              add_quiz_question(section_node, question)
            end
          end
        end # section node
      end

    end
  end
end
