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

module Importers
  class AssignmentGroupImporter < Importer
    self.item_class = AssignmentGroup

    def self.process_migration(data, migration)
      AssignmentGroup.suspend_callbacks(:update_student_grades) do
        add_groups_for_imported_assignments(data, migration)
        groups = data["assignment_groups"] || []
        groups.each do |group|
          next unless migration.import_object?("assignment_groups", group["migration_id"])

          begin
            import_from_migration(group, migration.context, migration)
          rescue
            migration.add_import_warning(t("#migration.assignment_group_type", "Assignment Group"), group[:title], $!)
          end
        end
        migration.context.assignment_groups.first.try(:fix_position_conflicts)
      end
    end

    def self.add_groups_for_imported_assignments(data, migration)
      return unless migration.migration_settings[:migration_ids_to_import] &&
                    migration.migration_settings[:migration_ids_to_import][:copy] &&
                    !migration.migration_settings[:migration_ids_to_import][:copy].empty?

      migration.migration_settings[:migration_ids_to_import][:copy]["assignment_groups"] ||= {}
      data["assignments"]&.each do |assignment_hash|
        a_hash = assignment_hash.with_indifferent_access
        if migration.import_object?("assignments", a_hash["migration_id"]) &&
           (group_mig_id = a_hash["assignment_group_migration_id"])
          migration.migration_settings[:migration_ids_to_import][:copy]["assignment_groups"][group_mig_id] = true
        end
      end
      other_objects = {
        "discussion_topics" => data["discussion_topics"],
        "quizzes" => data.dig("assessments", "assessments")
      }
      other_objects.each do |key, objects|
        objects&.each do |obj_hash|
          obj_hash = obj_hash.with_indifferent_access
          a_hash = obj_hash["assignment"]
          next unless a_hash && migration.import_object?(key, obj_hash["migration_id"]) &&
                      (group_mig_id = a_hash["assignment_group_migration_id"])

          # auto import the assignment group even if it's not actually in the top-level assignments list
          # and just nested inside the topic or quiz
          migration.migration_settings[:migration_ids_to_import][:copy]["assignment_groups"][group_mig_id] = true
        end
      end
    end

    def self.import_from_migration(hash, context, migration, item = nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:assignment_groups_to_import] && !hash[:assignment_groups_to_import][hash[:migration_id]]

      item ||= AssignmentGroup.where(context_id: context, context_type: context.class.to_s, id: hash[:id]).first
      item ||= AssignmentGroup.where(context_id: context, context_type: context.class.to_s, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= match_assignment_group_by_name(context, migration, hash[:title])
      item ||= context.assignment_groups.temp_record
      migration.add_imported_item(item)
      item.saved_by = :migration
      item.mark_as_importing!(migration)
      item.migration_id = hash[:migration_id]
      item.workflow_state = "available" if item.deleted?
      item.name = hash[:title]
      item.position = hash[:position].to_i if hash[:position] && hash[:position].to_i > 0
      item.group_weight = hash[:group_weight] if hash[:group_weight]

      rules = ""
      if hash[:rules].present?
        hash[:rules].each do |rule|
          case rule[:drop_type]
          when "drop_lowest", "drop_highest"
            rules += "#{rule[:drop_type]}:#{rule[:drop_count]}\n"
          when "never_drop"
            if context.respond_to?(:assignment_group_no_drop_assignments)
              context.assignment_group_no_drop_assignments[rule[:assignment_migration_id]] = item
            end
          end
        end
      end
      if rules.blank? && context.respond_to?(:assignment_group_no_drop_assignments)
        context.assignment_group_no_drop_assignments&.delete_if { |_k, v| v == item } # don't set never_drop rules if there are no drop rules
      end
      item.rules = rules.presence

      item.save!
      item
    end

    def self.match_assignment_group_by_name(context, migration, name)
      ag = context.assignment_groups.where(name:, migration_id: nil).first
      if ag && migration.for_master_course_import?
        # prevent overwriting assignment group settings in a pre-existing group that was matched by name
        downstream_changes = []
        downstream_changes << "group_weight" if ag.group_weight&.> 0
        downstream_changes << "rules" if ag.rules.present?
        if downstream_changes.any?
          tag = migration.master_course_subscription&.content_tag_for(ag)
          tag.downstream_changes |= downstream_changes
          tag.save!
        end
      end
      ag
    end
  end
end
