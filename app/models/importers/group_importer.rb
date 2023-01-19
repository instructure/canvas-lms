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
  class GroupImporter < Importer
    self.item_class = Group

    def self.process_migration(data, migration)
      groups = data["groups"] || []
      groups.each do |group|
        next unless migration.import_object?("groups", group["migration_id"])

        begin
          import_from_migration(group, migration.context, migration)
        rescue
          migration.add_import_warning(t("#migration.group_type", "Group"), group[:title], $!)
        end
      end
    end

    def self.import_from_migration(hash, context, migration, item = nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:groups_to_import] && !hash[:groups_to_import][hash[:migration_id]]

      item ||= Group.where(context_id: context, context_type: context.class.to_s, id: hash[:id]).first
      item ||= Group.where(context_id: context, context_type: context.class.to_s, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= context.groups.temp_record
      migration.add_imported_item(item)
      item.migration_id = hash[:migration_id]
      item.name = hash[:title]
      item.group_category = if hash[:group_category].present?
                              context.group_categories.where(name: hash[:group_category]).first_or_initialize
                            else
                              GroupCategory.imported_for(context)
                            end

      item.save!
      migration.add_imported_item(item)
      item
    end
  end
end
