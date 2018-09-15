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

require_dependency 'importers'

module Importers
  class AssignmentGroupImporter < Importer

    self.item_class = AssignmentGroup

    def self.process_migration(data, migration)
      AssignmentGroup.suspend_callbacks(:update_student_grades) do
        self.add_groups_for_imported_assignments(data, migration)
        groups = data['assignment_groups'] ? data['assignment_groups']: []
        groups.each do |group|
          if migration.import_object?("assignment_groups", group['migration_id'])
            begin
              import_from_migration(group, migration.context, migration)
            rescue
              migration.add_import_warning(t('#migration.assignment_group_type', "Assignment Group"), group[:title], $!)
            end
          end
        end
        migration.context.assignment_groups.first.try(:fix_position_conflicts)
      end
    end

    def self.add_groups_for_imported_assignments(data, migration)
      return unless data['assignments'] && migration.migration_settings[:migration_ids_to_import] &&
          migration.migration_settings[:migration_ids_to_import][:copy] &&
          migration.migration_settings[:migration_ids_to_import][:copy].length > 0

      migration.migration_settings[:migration_ids_to_import][:copy]['assignment_groups'] ||= {}
      data['assignments'].each do |assignment_hash|
        a_hash = assignment_hash.with_indifferent_access
        if migration.import_object?("assignments", a_hash['migration_id']) &&
            group_mig_id = a_hash['assignment_group_migration_id']
          migration.migration_settings[:migration_ids_to_import][:copy]['assignment_groups'][group_mig_id] = true
        end
      end
    end

    def self.import_from_migration(hash, context, migration, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:assignment_groups_to_import] && !hash[:assignment_groups_to_import][hash[:migration_id]]
      item ||= AssignmentGroup.where(context_id: context, context_type: context.class.to_s, id: hash[:id]).first
      item ||= AssignmentGroup.where(context_id: context, context_type: context.class.to_s, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= context.assignment_groups.where(name: hash[:title], migration_id: nil).first
      item ||= context.assignment_groups.temp_record
      migration.add_imported_item(item)
      item.saved_by = :migration
      item.migration_id = hash[:migration_id]
      item.workflow_state = 'available' if item.deleted?
      item.name = hash[:title]
      item.position = hash[:position].to_i if hash[:position] && hash[:position].to_i > 0
      item.group_weight = hash[:group_weight] if hash[:group_weight]

      rules = ""
      if hash[:rules] && hash[:rules].length > 0
        hash[:rules].each do |rule|
          if rule[:drop_type] == "drop_lowest" || rule[:drop_type] == "drop_highest"
            rules += "#{rule[:drop_type]}:#{rule[:drop_count]}\n"
          elsif rule[:drop_type] == "never_drop"
            if context.respond_to?(:assignment_group_no_drop_assignments)
              context.assignment_group_no_drop_assignments[rule[:assignment_migration_id]] = item
            end
          end
        end
      end
      if rules.blank? && context.respond_to?(:assignment_group_no_drop_assignments)
        context.assignment_group_no_drop_assignments&.delete_if{|k, v| v == item} # don't set never_drop rules if there are no drop rules
      end
      item.rules = rules.presence

      item.save!
      item
    end
  end
end
