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

# Scenarios:
# Academic Benchmark Import
# Blueprint Sync
# Course copy
module Importers
  class LearningOutcomeImporter < Importer
    self.item_class = LearningOutcome

    def self.process_migration(data, migration)
      selectable_outcomes = migration.context.respond_to?(:root_account) &&
                            migration.context.root_account.feature_enabled?(:selectable_outcomes_in_course_copy)
      outcomes = data["learning_outcomes"] || []
      migration.outcome_to_id_map = {}
      migration.copied_external_outcome_map = {}
      outcomes.each do |outcome|
        import_item = migration.import_object?("learning_outcomes", outcome["migration_id"])
        import_item ||= migration.import_object?("learning_outcome_groups", outcome["migration_id"]) if selectable_outcomes
        next unless import_item || selectable_outcomes

        begin
          if outcome[:type] == "learning_outcome_group"
            Importers::LearningOutcomeGroupImporter.import_from_migration(outcome, migration, nil, selectable_outcomes && !import_item)
          elsif !selectable_outcomes || import_item
            Importers::LearningOutcomeImporter.import_from_migration(outcome, migration)
          end
        rescue
          migration.add_import_warning(t("#migration.learning_outcome_type", "Learning Outcome"), outcome[:title], $!)
        end
      end
    end

    def self.import_from_migration(hash, migration, item = nil)
      # For Academic Benchmark (global outcomes) the context is Account.site_admin
      # For Course copy and Blueprint Sync the Context is the course wea are copying data to
      context = migration.context
      hash = hash.with_indifferent_access
      outcome = nil
      previously_imported = false
      if !item && hash[:external_identifier]
        unless migration.cross_institution?
          outcome = if hash[:is_global_outcome]
                      LearningOutcome.active.where(id: hash[:external_identifier], context_id: nil).first
                    else
                      context.available_outcome(hash[:external_identifier])
                    end
        end

        outcome ||= LearningOutcome.active.find_by(vendor_guid: hash[:vendor_guid]) if hash[:vendor_guid].present?
        if outcome && outcome.short_description != hash[:title]
          # Help prevent linking to the wrong outcome if copying into a different install of canvas
          # (using older migration packages that lack the root account uuid)
          outcome = nil
        end

        unless outcome
          migration.add_warning(t(:no_context_found, %(The external Learning Outcome couldn't be found for "%{title}", creating a copy.), title: hash[:title]))
          migration.copied_external_outcome_map[hash[:external_identifier]] = hash[:migration_id]
        end
      end

      if hash[:migration_id].present? && (migration.canvas_import? || migration.for_course_copy?)
        previous_outcome = migration.find_imported_migration_item(LearningOutcome, hash[:migration_id])
        if previous_outcome
          previously_imported = true
          outcome = previous_outcome
        end
      end

      if outcome
        item = outcome
        if context.respond_to?(:root_account) && context.root_account.feature_enabled?(:outcome_alignments_course_migration)
          migration.add_imported_item(item, key: CC::CCHelper.create_key(item, global: true))
        end
      else
        if hash[:is_global_standard]
          if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
            # import from vendor with global outcomes
            # When creating an Academic Benchmark the context is set to nil. Does not belong to a Context
            hash[:learning_outcome_group] ||= LearningOutcomeGroup.global_root_outcome_group
            item ||= LearningOutcome.global.where(migration_id: hash[:migration_id]).first if hash[:migration_id] && !migration.cross_institution?
            item ||= LearningOutcome.global.where(vendor_guid: hash[:vendor_guid]).first if hash[:vendor_guid]
            item ||= LearningOutcome.new
          else
            migration.add_warning(t(:no_global_permission, %(You're not allowed to manage global outcomes, can't add "%{title}"), title: hash[:title]))
            return
          end
        else
          if hash[:migration_id]
            item ||= LearningOutcome.where(context_id: context, context_type: context.class.to_s)
                                    .where(migration_id: hash[:migration_id]).first
          end
          item ||= LearningOutcome.where(context_id: context, context_type: context.class.to_s, vendor_guid: hash[:vendor_guid]).first if hash[:vendor_guid]
          item ||= context.created_learning_outcomes.temp_record
          item.context = context
          item.mark_as_importing!(migration)
        end
        item.migration_id = hash[:migration_id]
        item.vendor_guid = hash[:vendor_guid]
        item.low_grade = hash[:low_grade]
        item.high_grade = hash[:high_grade]
        item.workflow_state = "active" if item.deleted?
        item.short_description = hash[:title]
        item.description = migration.convert_html(hash[:description], :learning_outcome, hash[:migration_id], :description) if hash[:description]
        item.copied_from_outcome_id = migration.for_course_copy? ? hash[:copied_from_outcome_id] : nil
        assessed = item.assessed?
        unless assessed
          item.calculation_method = hash[:calculation_method] || item.calculation_method
          item.calculation_int = hash[:calculation_int] || item.calculation_int
        end

        if hash[:ratings]
          unless assessed
            item.data = { rubric_criterion: {} }
            item.data[:rubric_criterion][:ratings] = hash[:ratings] ? hash[:ratings].map(&:symbolize_keys) : []
            item.data[:rubric_criterion][:mastery_points] = hash[:mastery_points]
            item.data[:rubric_criterion][:points_possible] = hash[:points_possible]
          end
          item.data[:rubric_criterion][:description] = item.short_description || item.description
        end

        item.save!

        migration.add_imported_item(item)
      end

      # don't add a deleted outcome to an outcome group, or align it with an assignment
      # (blueprint migration will not undelete outcomes deleted downstream)
      return item if item.deleted?

      # don't implicitly add an outcome to the root outcome group if it's already in an outcome group
      if hash[:learning_outcome_group].present? || context.learning_outcome_links.not_deleted.where(content: item).none?

        log = hash[:learning_outcome_group] || context.root_outcome_group

        outcome_link = context.learning_outcome_links.find_by(content: item, migration_id: hash[:migration_id])
        if outcome_link
          log.adopt_outcome_link(outcome_link)
        else
          outcome_link = log.add_outcome(item, migration_id: hash[:migration_id])
        end
        migration.add_imported_item(outcome_link)
      end

      if hash[:alignments] && !previously_imported
        # This part is executed for Blueprint Sync and Course Copy
        alignments = hash[:alignments].sort_by { |a| a[:position].to_i }
        alignments.each do |alignment|
          next unless alignment[:content_type] && alignment[:content_id]

          asset = nil

          case alignment[:content_type]
          when "Assignment"
            asset = Assignment.where(context_id: context, context_type: context.class.to_s, migration_id: alignment[:content_id]).first
          when "AssessmentQuestionBank"
            asset = AssessmentQuestionBank.where(context_id: context, context_type: context.class.to_s, migration_id: alignment[:content_id]).first
          end

          if asset
            options = alignment.slice(:mastery_type, :mastery_score)
            item.align(asset, context, options)
          end
        end
      end

      # Create OutcomeFriendlyDescription from course import
      if item && Account.site_admin.feature_enabled?(:outcomes_friendly_description) && item.context_type == "Course" && hash[:friendly_description].present?
        OutcomeFriendlyDescription.find_or_create_by(context: item.context, learning_outcome: item).update(description: hash[:friendly_description])
      end

      migration.outcome_to_id_map[hash[:migration_id]] = item.id

      item
    end
  end
end
