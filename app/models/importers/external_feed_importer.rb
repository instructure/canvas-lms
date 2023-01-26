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
  class ExternalFeedImporter < Importer
    self.item_class = ExternalFeed

    def self.process_migration(data, migration)
      tools = data["external_feeds"] || []
      to_import = migration.to_import "external_feeds"
      tools.each do |tool|
        next unless tool["migration_id"] && (!to_import || to_import[tool["migration_id"]])

        begin
          import_from_migration(tool, migration.context, migration)
        rescue
          migration.add_import_warning(t("#migration.external_feed_type", "External Feed"), tool[:title], $!)
        end
      end
    end

    def self.import_from_migration(hash, context, migration, item = nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:external_feeds_to_import] && !hash[:external_feeds_to_import][hash[:migration_id]]

      item ||= find_or_initialize_from_migration(hash, context)
      item.migration_id = hash[:migration_id]
      item.url = hash[:url]
      item.title = hash[:title]
      item.verbosity = hash[:verbosity]
      item.header_match = hash[:header_match] unless hash[:header_match].blank?

      item.save!
      migration.add_imported_item(item)
      item
    end

    def self.find_or_initialize_from_migration(hash, context)
      if hash[:migration_id]
        item = ExternalFeed.where(
          context_id: context,
          context_type: context.class.to_s,
          migration_id: hash[:migration_id]
        ).first
      end
      if hash[:url]
        item ||= ExternalFeed.where(
          context_id: context,
          context_type: context.class.to_s,
          url: hash[:url],
          header_match: hash[:header_match].presence,
          verbosity: hash[:verbosity]
        ).first
      end
      item ||= context.external_feeds.temp_record
      item
    end
  end
end
