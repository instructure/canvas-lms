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
            assessment[:migration] = migration
            Importers::QuizImporter.import_from_migration(assessment, migration.context, question_data, nil, allow_update)
          rescue
            migration.add_import_warning(t('#migration.quiz_type', "Quiz"), assessment[:title], $!)
          end
        end
      end
    end

    # Import a quiz from a hash.
    # It assumes that all the referenced questions are already in the database
    def self.import_from_migration(hash, context, question_data, item=nil, allow_update = false)
      hash = hash.with_indifferent_access
      # there might not be an import id if it's just a text-only type...
      item ||= Quizzes::Quiz.find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id]) if hash[:id]
      item ||= Quizzes::Quiz.find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
      if item && !allow_update
        if item.deleted?
          item.workflow_state = hash[:available] ? 'available' : 'created'
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
      hash[:missing_links] = []
      item.description = ImportedHtmlConverter.convert(hash[:description], context, {:missing_links => hash[:missing_links]})


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

      item.save!

      if context.respond_to?(:content_migration) && context.content_migration
        context.content_migration.add_missing_content_links(
          :class => item.class.to_s,
          :id => item.id, :missing_links => hash[:missing_links],
          :url => "/#{context.class.to_s.demodulize.underscore.pluralize}/#{context.id}/#{item.class.to_s.demodulize.underscore.pluralize}/#{item.id}"
        )
      end

      if question_data
        hash[:questions] ||= []

        if question_data[:qq_data] || question_data[:aq_data]
          existing_questions = item.quiz_questions.active.where("migration_id IS NOT NULL").select([:id, :migration_id]).index_by(&:migration_id)
        end

        if question_data[:qq_data]
          question_data[:qq_data].values.each do |q|
            existing_question = existing_questions[q['migration_id']]
            q['quiz_question_id'] = existing_question.id if existing_question
          end
        end

        if question_data[:aq_data]
          question_data[:aq_data].values.each do |q|
            existing_question = existing_questions[q['migration_id']]
            q['quiz_question_id'] = existing_question.id if existing_question
          end
        end

        hash[:questions].each_with_index do |question, i|
          case question[:question_type]
          when "question_reference"
            if qq = question_data[:qq_data][question[:migration_id]]
              qq[:position] = i + 1
              if qq[:assessment_question_migration_id]
                if aq = question_data[:aq_data][qq[:assessment_question_migration_id]]
                  qq['assessment_question_id'] = aq['assessment_question_id']
                  aq_hash = ::Importers::AssessmentQuestionImporter.prep_for_import(qq, context)
                  Quizzes::QuizQuestion.import_from_migration(aq_hash, context, item)
                else
                  aq_hash = ::Importers::AssessmentQuestionImporter.import_from_migration(qq, context)
                  qq['assessment_question_id'] = aq_hash['assessment_question_id']
                  Quizzes::QuizQuestion.import_from_migration(aq_hash, context, item)
                end
              end
            elsif aq = question_data[:aq_data][question[:migration_id]]
              aq[:position] = i + 1
              aq[:points_possible] = question[:points_possible] if question[:points_possible]
              Quizzes::QuizQuestion.import_from_migration(aq, context, item)
            end
          when "question_group"
            Importers::QuizGroupImporter.import_from_migration(question, context, item, question_data, i + 1, hash[:migration])
          when "text_only_question"
            qq = item.quiz_questions.new
            qq.question_data = question
            qq.position = i + 1
            qq.save!
          end
        end
      end
      item.reload # reload to catch question additions

      if hash[:assignment]
        if hash[:assignment][:migration_id]
          item.assignment ||= Quizzes::Quiz.find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:assignment][:migration_id])
        end
        item.assignment = nil if item.assignment && item.assignment.quiz && item.assignment.quiz.id != item.id
        item.assignment ||= context.assignments.new

        item.assignment = ::Importers::AssignmentImporter.import_from_migration(hash[:assignment], context, item.assignment, item)

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
        if g = context.assignment_groups.find_by_migration_id(hash[:assignment_group_migration_id])
          item.assignment_group_id = g.id
        end
      end

      item.save
      item.assignment.save if item.assignment && item.assignment.changed?

      context.imported_migration_items << item if context.imported_migration_items
      item
    end

  end
end