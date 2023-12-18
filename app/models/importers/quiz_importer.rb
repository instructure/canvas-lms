# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
      assessments = (data["assessments"] && data["assessments"]["assessments"]) || []
      assessments.each do |assmnt|
        next unless assmnt["questions"]

        assmnt["questions"].each do |q|
          if q["question_type"] == "question_group"
            next unless q["questions"]

            q["questions"].each do |ref|
              preprocess_quiz_question(ref, new_aqs, references)
              assmnt_map[ref["migration_id"]] = [assmnt["migration_id"], assmnt["title"]]
            end
          else
            preprocess_quiz_question(q, new_aqs, references)
            assmnt_map[q["migration_id"]] = [assmnt["migration_id"], assmnt["title"]]
          end
        end
      end

      data["assessment_questions"] ||= {}
      data["assessment_questions"]["assessment_questions"] ||= []
      new_aqs.each do |new_aq|
        unless data["assessment_questions"]["assessment_questions"].detect { |aq| aq["migration_id"] == new_aq["migration_id"] }
          data["assessment_questions"]["assessment_questions"] << new_aq
        end
      end

      # also default question bank name to quiz name
      data["assessment_questions"]["assessment_questions"].each do |aq|
        next unless aq["question_bank_id"].blank? && aq["question_bank_migration_id"].blank?

        assmnt_mig_id, assmnt_title = assmnt_map[aq["migration_id"]]
        aq["question_bank_name"] ||= assmnt_title
        aq["question_bank_migration_id"] = CC::CCHelper.create_key("#{assmnt_mig_id}_#{aq["question_bank_name"]}_question_bank")
        aq["is_quiz_question_bank"] = true
      end

      dedup_assessment_questions(data["assessment_questions"]["assessment_questions"], references)
    end

    def self.preprocess_quiz_question(quiz_question, new_aqs, references)
      quiz_question["migration_id"] ||= CC::CCHelper.create_key(quiz_question, "quiz_question")

      # convert to a question reference if possible
      unless ["question_reference", "text_only_question"].include?(quiz_question["question_type"])
        aq = quiz_question.dup
        new_aqs << aq
        quiz_question["question_type"] = "question_reference"
      end

      references << quiz_question if quiz_question["question_type"] == "question_reference"
    end

    QUIZ_QUESTION_KEYS = ["position", "points_possible"].freeze
    IGNORABLE_QUESTION_KEYS = QUIZ_QUESTION_KEYS + %w[answers
                                                      assessment_question_migration_id
                                                      migration_id
                                                      question_bank_migration_id
                                                      question_bank_id
                                                      is_quiz_question_bank
                                                      question_bank_name]

    def self.check_question_equality(question1, question2)
      stripped_q1 = question1.except(*IGNORABLE_QUESTION_KEYS)
      stripped_q2 = question2.except(*IGNORABLE_QUESTION_KEYS)
      stripped_q1_answers = (question1["answers"] || []).map { |ans| ans.except("id") }
      stripped_q2_answers = (question2["answers"] || []).map { |ans| ans.except("id") }

      stripped_q1 == stripped_q2 && stripped_q1_answers == stripped_q2_answers
    end

    def self.dedup_assessment_questions(questions, references)
      # it used to skip these in the importer, instead let's remove them outright
      aq_dups = []

      questions.each_with_index do |quiz_question, qq_index|
        aq_mig_id = quiz_question["assessment_question_migration_id"]
        next unless aq_mig_id

        questions.each_with_index do |matching_question, mq_index|
          next if qq_index == mq_index # don't match to yourself

          # make sure that the match's core question data is identical
          if aq_mig_id == matching_question["migration_id"] &&
             check_question_equality(quiz_question, matching_question)
            aq_dups << [quiz_question, matching_question["migration_id"]]
          end
        end
      end

      aq_dups.each do |aq_dup, new_mig_id|
        references.each do |ref|
          if ref["migration_id"] == aq_dup["migration_id"]
            ref["quiz_question_migration_id"] = ref["migration_id"]
            ref["migration_id"] = new_mig_id
            QUIZ_QUESTION_KEYS.each { |k| ref[k] ||= aq_dup[k] }
          end
          if ref["assessment_question_migration_id"] == aq_dup["migration_id"]
            ref["assessment_question_migration_id"] = new_mig_id
            QUIZ_QUESTION_KEYS.each { |k| ref[k] ||= aq_dup[k] }
          end
        end
        questions.delete(aq_dup)
      end
    end

    def self.process_migration(data, migration, question_data)
      assessments = data["assessments"] ? data["assessments"]["assessments"] : []
      assessments ||= []
      assessments.each do |assessment|
        migration_id = assessment["migration_id"] || assessment["assessment_id"]
        next unless migration.import_object?("quizzes", migration_id)

        allow_update = false
        # allow update if we find an existing item based on this migration setting
        if (item_id = migration.migration_settings[:quiz_id_to_update])
          allow_update = true
          assessment[:id] = item_id.to_i
          if assessment[:assignment]
            assessment[:assignment][:id] = Quizzes::Quiz.find(item_id.to_i).try(:assignment_id)
          end
        end
        if assessment["assignment_migration_id"] &&
           (assignment = data["assignments"].find { |a| a["migration_id"] == assessment["assignment_migration_id"] })
          assignment["quiz_migration_id"] = migration_id
        end
        begin
          Importers::QuizImporter.import_from_migration(assessment, migration.context, migration, question_data, nil, allow_update)
        rescue
          migration.add_import_warning(t("#migration.quiz_type", "Quiz"), assessment[:title], $!)
        end
      end
    end

    # Import a quiz from a hash.
    # It assumes that all the referenced questions are already in the database
    def self.import_from_migration(hash, context, migration, question_data = nil, item = nil, allow_update = false)
      hash = hash.with_indifferent_access
      # there might not be an import id if it's just a text-only type...
      item ||= Quizzes::Quiz.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first if hash[:id]
      item ||= Quizzes::Quiz.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= context.quizzes.temp_record
      item.mark_as_importing!(migration)
      if item && !allow_update && item.deleted?
        item.workflow_state = (hash[:available] || !item.can_unpublish?) ? "available" : "unpublished"
        item.saved_by = :migration
        item.quiz_groups.destroy_all
        item.quiz_questions.preload(assessment_question: :assessment_question_bank).destroy_all
        item.save
      end
      new_record = item.new_record? || item.deleted?

      hash[:due_at] ||= hash[:due_date] if hash.key?(:due_date)
      hash[:due_at] ||= hash[:grading][:due_date] if hash[:grading]
      master_migration = migration&.for_master_course_import? # propagate null dates only for blueprint syncs
      item.lock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:lock_at]) if master_migration || hash[:lock_at]
      item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at]) if master_migration || hash[:unlock_at]
      item.due_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:due_at]) if master_migration || hash[:due_at]
      item.show_correct_answers_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:show_correct_answers_at]) if master_migration || hash[:show_correct_answers_at]
      item.hide_correct_answers_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:hide_correct_answers_at]) if master_migration || hash[:hide_correct_answers_at]
      item.scoring_policy = hash[:which_attempt_to_keep] if master_migration || hash[:which_attempt_to_keep]

      unless migration.quizzes_next_migration? # The description is mapped to "instructions" in NQ
        item.description = migration.convert_html(hash[:description], :quiz, hash[:migration_id], :description)
      end

      %w[
        migration_id
        title
        allowed_attempts
        time_limit
        shuffle_answers
        disable_timer_autosubmission
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
        one_time_results
        show_correct_answers_last_attempt
      ].each do |attr|
        attr = attr.to_sym
        if hash.key?(attr)
          item.send(:"#{attr}=", hash[attr])
        elsif master_migration
          item.send(:"#{attr}=", nil)
        end
      end

      item.saved_by = :migration
      item.save!
      recache_due_dates = item.assignment&.needs_update_cached_due_dates # quiz ends up getting reloaded by the end
      build_assignment = false

      import_questions(item, hash, context, migration, question_data, new_record)

      if hash[:assignment]
        if hash[:assignment][:migration_id] && !hash[:assignment][:migration_id].start_with?(MasterCourses::MIGRATION_ID_PREFIX)
          item.assignment ||= Quizzes::Quiz.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:assignment][:migration_id]).first
        end
        item.assignment = nil if item.assignment&.quiz && item.assignment.quiz.id != item.id
        item.assignment ||= context.assignments.temp_record
        item.assignment = ::Importers::AssignmentImporter.import_from_migration(hash[:assignment], context, migration, item.assignment, item)
      elsif !item.assignment && (grading = hash[:grading])
        item.quiz_type = "assignment"
        hash[:assignment_group_migration_id] ||= grading[:assignment_group_migration_id]
      end

      if hash[:assignment_overrides]
        added_overrides = false
        hash[:assignment_overrides].each do |o|
          next if o[:set_id].to_i == AssignmentOverride::NOOP_MASTERY_PATHS &&
                  o[:set_type] == AssignmentOverride::SET_TYPE_NOOP &&
                  !context.conditional_release?

          override = item.assignment_overrides.where(o.slice(:set_type, :set_id)).first
          override ||= item.assignment_overrides.build
          override.set_type = o[:set_type]
          override.title = o[:title]
          override.set_id = o[:set_id]
          AssignmentOverride.overridden_dates.each do |field|
            next unless o.key?(field)

            override.send :"override_#{field}", Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(o[field])
          end
          override.save!
          added_overrides = true
          migration.add_imported_item(override,
                                      key: [item.migration_id, override.set_type, override.set_id].join("/"))
        end
        if hash.key?(:only_visible_to_overrides) && added_overrides
          item.only_visible_to_overrides = hash[:only_visible_to_overrides]
        end
      end

      if item.graded? && !item.assignment && !(migration.canvas_import? || hash["assignment_migration_id"])
        build_assignment = true
      end

      item.generate_quiz_data if hash[:available] || item.published?

      if hash.key?(:points_possible) && migration.quizzes_next_migration?
        item.points_possible = hash[:points_possible]

        # prevent overriding the points_possible field
        item.saved_by_new_quizzes_migration = true
      end

      if hash[:available]
        item.workflow_state = "available"
        item.published_at = Time.now
      elsif item.can_unpublish? && (new_record || master_migration)
        item.workflow_state = "unpublished"
        item.assignment.workflow_state = "unpublished" if item.assignment
      end

      if hash[:assignment_group_migration_id] &&
         (g = context.assignment_groups.where(migration_id: hash[:assignment_group_migration_id]).first)
        item.assignment_group = g
      end

      if new_record && item.for_assignment? && !item.assignment && item.can_unpublish?
        item.workflow_state = "unpublished"
      end

      if build_assignment
        item.build_assignment(force: true)
        item.assignment.points_possible = item.points_possible
      end

      item.root_entries(true) if !item.available? && !item.survey? # reload items so we get accurate points
      item.notify_of_update = false
      item.save
      item.assignment.save_without_broadcasting if item.assignment&.changed?
      if recache_due_dates
        migration.find_imported_migration_item(Assignment, item.assignment.migration_id)&.needs_update_cached_due_dates = true
      end

      migration.add_imported_item(item)
      item.saved_by = nil

      item
    end

    def self.import_questions(item, hash, context, migration, question_data, new_record)
      if migration.for_master_course_import? && !new_record
        if item.edit_types_locked_for_overwrite_on_import.include?(:content)
          migration.add_skipped_item(item.migration_id)
          return
        end

        if hash[:questions]
          # either the quiz hasn't been changed downstream or we've re-locked it - delete all the questions/question_groups we're not going to (re)import in
          importing_question_mig_ids = hash[:questions].map do |q|
            if q[:questions]
              q[:questions].map { |qq| qq[:quiz_question_migration_id] || qq[:migration_id] }
            else
              q[:quiz_question_migration_id] || q[:migration_id]
            end
          end.flatten
          item.quiz_questions.not_deleted.where.not(migration_id: importing_question_mig_ids).update_all(workflow_state: "deleted")

          # remove the quiz groups afterwards so any of their dependent quiz questions are deleted first and we don't run into any Restrictor errors
          importing_qgroup_mig_ids = hash[:questions].select { |q| q[:question_type] == "question_group" }.pluck(:migration_id)
          item.quiz_groups.where.not(migration_id: importing_qgroup_mig_ids).destroy_all
        end
      end
      return unless question_data

      question_data[:qq_ids] ||= {}
      hash[:questions] ||= []

      unless question_data[:qq_ids][item.migration_id]
        question_data[:qq_ids][item.migration_id] = {}
        existing_questions = item.quiz_questions.active.where.not(migration_id: nil).pluck(:id, :migration_id)
        existing_questions.each do |id, mig_id|
          question_data[:qq_ids][item.migration_id][mig_id] = id
        end
      end

      !migration.quizzes_next_banks_migration? && hash[:questions].each_with_index do |question, i|
        case question[:question_type]
        when "question_reference"
          if (aq = question_data[:aq_data][question[:migration_id]] || question_data[:aq_data][question[:assessment_question_migration_id]])
            Importers::QuizQuestionImporter.import_from_migration(aq,
                                                                  question,
                                                                  i + 1,
                                                                  question_data[:qq_ids][item.migration_id],
                                                                  context,
                                                                  migration,
                                                                  item)
          end
        when "question_group"
          Importers::QuizGroupImporter.import_from_migration(question, context, item, question_data, i + 1, migration)
        when "text_only_question"
          Importers::QuizQuestionImporter.import_from_migration(question,
                                                                question,
                                                                i + 1,
                                                                question_data[:qq_ids][item.migration_id],
                                                                context,
                                                                migration,
                                                                item)
        end
      end
      item.reload # reload to catch question additions
    end
  end
end
