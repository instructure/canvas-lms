#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

module Importers
  class QuizImporter < Importer

    self.item_class = Quizzes::Quiz

    # try to standardize the data to make life easier later on
    # in particular, strip out all of the embedded questions and add explicitly to assessment_questions
    def self.preprocess_migration_data(data)
      new_aqs = []
      assmnt_map = {}

      references = []
      # turn all quiz questions to question references
      assessments = (data['assessments'] && data['assessments']['assessments']) || []
      assessments.each do |assmnt|
        next unless assmnt['questions']
        assmnt['questions'].each do |q|
          if q["question_type"] == "question_group"
            next unless q['questions']
            q['questions'].each do |ref|
              preprocess_quiz_question(ref, new_aqs, references)
              assmnt_map[ref['migration_id']] = [assmnt['migration_id'], assmnt['title']]
            end
          else
            preprocess_quiz_question(q, new_aqs, references)
            assmnt_map[q['migration_id']] = [assmnt['migration_id'], assmnt['title']]
          end
        end
      end

      data['assessment_questions'] ||= {}
      data['assessment_questions']['assessment_questions'] ||= []
      new_aqs.each do |new_aq|
        unless data['assessment_questions']['assessment_questions'].detect{|aq| aq['migration_id'] == new_aq['migration_id']}
          data['assessment_questions']['assessment_questions'] << new_aq
        end
      end

      # also default question bank name to quiz name
      data['assessment_questions']['assessment_questions'].each do |aq|
        if aq['question_bank_id'].blank? && aq['question_bank_migration_id'].blank?
          assmnt_mig_id, assmnt_title = assmnt_map[aq['migration_id']]
          aq['question_bank_name'] ||= assmnt_title
          aq['question_bank_migration_id'] = CC::CCHelper.create_key("#{assmnt_mig_id}_#{aq['question_bank_name']}_question_bank")
          aq['is_quiz_question_bank'] = true
        end
      end

      dedup_assessment_questions(data['assessment_questions']['assessment_questions'], references)
    end

    def self.preprocess_quiz_question(quiz_question, new_aqs, references)
      quiz_question['migration_id'] ||= CC::CCHelper.create_key(quiz_question, 'quiz_question')

      # convert to a question reference if possible
      unless ['question_reference', 'text_only_question'].include?(quiz_question['question_type'])
        aq = quiz_question.dup
        new_aqs << aq
        quiz_question['question_type'] = 'question_reference'
      end

      references << quiz_question if quiz_question['question_type'] == 'question_reference'
    end

    def self.dedup_assessment_questions(questions, references)
      # it used to skip these in the importer, instead let's remove them outright
      aq_dups = []
      qq_keys = ['position', 'points_possible']
      keys_to_ignore = qq_keys + ['assessment_question_migration_id', 'migration_id', 'question_bank_migration_id',
                                  'question_bank_id', 'is_quiz_question_bank', 'question_bank_name']

      questions.each_with_index do |quiz_question, qq_index|
        aq_mig_id = quiz_question['assessment_question_migration_id']
        next unless aq_mig_id

        questions.each_with_index do |matching_question, mq_index|
          next if qq_index == mq_index # don't match to yourself

          if aq_mig_id == matching_question['migration_id']
            # make sure that the match's core question data is identical
            if quiz_question.reject{|k, v| keys_to_ignore.include?(k)} == matching_question.reject{|k, v| keys_to_ignore.include?(k)}
              aq_dups << [quiz_question, matching_question['migration_id']]
            end
          end
        end
      end
      aq_dups.each do |aq_dup, new_mig_id|
        references.each do |ref|

          if ref['migration_id'] == aq_dup['migration_id']
            ref['migration_id'] = new_mig_id
            qq_keys.each{|k| ref[k] ||= aq_dup[k]}
          end
          if ref['assessment_question_migration_id'] == aq_dup['migration_id']
            ref['assessment_question_migration_id'] = new_mig_id
            qq_keys.each{|k| ref[k] ||= aq_dup[k]}
          end
        end
        questions.delete(aq_dup)
      end
    end

    def self.process_migration(data, migration, question_data)
      assessments = data['assessments'] ? data['assessments']['assessments'] : []
      assessments ||= []
      assessments.each do |assessment|
        migration_id = assessment['migration_id'] || assessment['assessment_id']
        if migration.import_object?("quizzes", migration_id)
          allow_update = false
          # allow update if we find an existing item based on this migration setting
          if item_id = migration.migration_settings[:quiz_id_to_update]
            allow_update = true
            assessment[:id] = item_id.to_i
            if assessment[:assignment]
              assessment[:assignment][:id] = Quizzes::Quiz.find(item_id.to_i).try(:assignment_id)
            end
          end
          if assessment['assignment_migration_id']
            if assignment = data['assignments'].find { |a| a['migration_id'] == assessment['assignment_migration_id'] }
              assignment['quiz_migration_id'] = migration_id
            end
          end
          begin
            Importers::QuizImporter.import_from_migration(assessment, migration.context, migration, question_data, nil, allow_update)
          rescue
            migration.add_import_warning(t('#migration.quiz_type', "Quiz"), assessment[:title], $!)
          end
        end
      end
    end

    # Import a quiz from a hash.
    # It assumes that all the referenced questions are already in the database
    def self.import_from_migration(hash, context, migration=nil, question_data=nil, item=nil, allow_update = false)
      hash = hash.with_indifferent_access
      # there might not be an import id if it's just a text-only type...
      item ||= Quizzes::Quiz.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first if hash[:id]
      item ||= Quizzes::Quiz.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first if hash[:migration_id]
      if item && !allow_update
        if item.deleted?
          item.workflow_state = hash[:available] ? 'available' : 'created'
          item.saved_by = :migration
          item.save
        end
      end
      item ||= context.quizzes.new

      hash[:due_at] ||= hash[:due_date]
      hash[:due_at] ||= hash[:grading][:due_date] if hash[:grading]
      item.lock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:lock_at]) if hash[:lock_at]
      item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at]) if hash[:unlock_at]
      item.due_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:due_at]) if hash[:due_at]
      item.show_correct_answers_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:show_correct_answers_at]) if hash[:show_correct_answers_at]
      item.hide_correct_answers_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:hide_correct_answers_at]) if hash[:hide_correct_answers_at]
      item.scoring_policy = hash[:which_attempt_to_keep] if hash[:which_attempt_to_keep]

      missing_links = []
      item.description = ImportedHtmlConverter.convert(hash[:description], context, migration) do |warn, link|
        missing_links << link if warn == :missing_link
      end


      %w[
        migration_id
        title
        allowed_attempts
        time_limit
        shuffle_answers
        show_correct_answers
        points_possible
        hide_results
        access_code
        ip_filter
        scoring_policy
        require_lockdown_browser
        require_lockdown_browser_for_results
        anonymous_submissions
        could_be_locked
        quiz_type
        one_question_at_a_time
        cant_go_back
        require_lockdown_browser_monitor
        lockdown_browser_monitor_data
      ].each do |attr|
        attr = attr.to_sym
        item.send("#{attr}=", hash[attr]) if hash.key?(attr)
      end

      item.saved_by = :migration
      item.save!

      if migration
        migration.add_missing_content_links(
          :class => item.class.to_s,
          :id => item.id, :missing_links => missing_links,
          :url => "/#{context.class.to_s.demodulize.underscore.pluralize}/#{context.id}/#{item.class.to_s.demodulize.underscore.pluralize}/#{item.id}"
        )
      end

      if question_data
        question_data[:qq_ids] ||= {}
        hash[:questions] ||= []

        unless question_data[:qq_ids][item.migration_id]
          question_data[:qq_ids][item.migration_id] = {}
          existing_questions = item.quiz_questions.active.where("migration_id IS NOT NULL").select([:id, :migration_id])
          existing_questions.each do |eq|
            question_data[:qq_ids][item.migration_id][eq.migration_id] = eq.id
          end
        end

        hash[:questions].each_with_index do |question, i|
          case question[:question_type]
          when "question_reference"
            if aq = (question_data[:aq_data][question[:migration_id]] || question_data[:aq_data][question[:assessment_question_migration_id]])
              Importers::QuizQuestionImporter.import_from_migration(aq, question, i + 1,
                question_data[:qq_ids][item.migration_id], context, migration, item)
            end
          when "question_group"
            Importers::QuizGroupImporter.import_from_migration(question, context, item, question_data, i + 1, migration)
          when "text_only_question"
            Importers::QuizQuestionImporter.import_from_migration(question, question, i + 1,
              question_data[:qq_ids][item.migration_id], context, migration, item)
          end
        end
      end
      item.reload # reload to catch question additions

      if hash[:assignment]
        if hash[:assignment][:migration_id]
          item.assignment ||= Quizzes::Quiz.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:assignment][:migration_id]).first
        end
        item.assignment = nil if item.assignment && item.assignment.quiz && item.assignment.quiz.id != item.id
        item.assignment ||= context.assignments.new

        item.assignment = ::Importers::AssignmentImporter.import_from_migration(hash[:assignment], context, migration, item.assignment, item)

        if !hash[:available]
          item.workflow_state = 'unpublished'
          item.assignment.workflow_state = 'unpublished'
        end
      elsif !item.assignment && grading = hash[:grading]
        # The actual assignment will be created when the quiz is published
        item.quiz_type = 'assignment'
        hash[:assignment_group_migration_id] ||= grading[:assignment_group_migration_id]
      end

      if hash[:available]
        item.generate_quiz_data
        item.workflow_state = 'available'
        item.published_at = Time.now
      end

      if hash[:assignment_group_migration_id]
        if g = context.assignment_groups.where(migration_id: hash[:assignment_group_migration_id]).first
          item.assignment_group = g
        end
      end

      if item.for_assignment? && !item.assignment
        item.workflow_state = 'unpublished'
      end

      item.save
      item.assignment.save if item.assignment && item.assignment.changed?

      migration.add_imported_item(item) if migration
      item.saved_by = nil
      item
    end

  end
end
