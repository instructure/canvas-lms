# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
# Imports ContentTags into whatever module contains them without importing the module.
# Useful in situations where:
#   - the module item got inserted into a different module to begin with
#   - the module item has been moved to a different module

module Importers
  class ContentTagImporter < Importer
    self.item_class = ContentTag

    def self.process_migration(data, migration)
      # Currently only horizon courses can process module items separate from
      # their modules but there shouldn't be anything preventing us from supporting
      # this more broadly.
      return unless migration.context.try(:horizon_course?)

      hash_modules = data["modules"] || []
      return if hash_modules.empty?

      hash_modules.each do |hash_module|
        # if this module is being imported we won't import its items separately.
        next if migration.import_module?(hash_module["migration_id"])

        items = hash_module["items"] || []
        next if items.empty?

        # load content tags into memory so we don't hit the db for every item
        item_migration_ids = items.filter_map { |item| item["item_migration_id"] }
        content_tags = ContentTag.where(migration_id: item_migration_ids, context: migration.context, tag_type: "context_module")
                                 .joins(:context_module)
                                 .to_a

        items.each do |item_hash|
          next unless migration.import_module_item?(item_hash["item_migration_id"])

          begin
            import_from_migration(item_hash, migration, content_tags)
          rescue
            title = item_hash["title"] || item_hash["linked_resource_title"]
            migration.add_import_warning(t("#migration.module_item_type", "Module Item"), title, $!)
          end
        end
      end
    end

    def self.import_from_migration(item_hash, migration, content_tags)
      mig_id = item_hash["item_migration_id"]

      # We are looking for all content tags with this migration id regardless
      # of which module they are in so that we can update content tags that might
      # have been moved or added to a different module.
      tags = content_tags.select { |tag| tag.migration_id == mig_id }
      tags.each do |tag|
        ContextModuleImporter.add_module_item_from_migration(
          tag.context_module,
          item_hash,
          0,
          migration.context,
          {},
          migration
        )
      rescue
        title = hash["title"] || hash["linked_resource_title"]
        migration.add_import_warning(t("#migration.module_item_type", "Module Item"), title, $!)
      end
    end
  end
end
