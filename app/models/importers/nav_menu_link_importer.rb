# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  class NavMenuLinkImporter < Importer
    self.item_class = NavMenuLink

    def self.process_migration(data, migration)
      return unless migration.import_object?("course_settings", "")
      return unless migration.context.root_account.feature_enabled?(:nav_menu_links)

      nav_menu_links = data["nav_menu_links"]&.map(&:with_indifferent_access)
      return if nav_menu_links.blank?

      # Preload existing links to avoid N+1 queries
      existing_links = existing_links_by_migration_id(nav_menu_links:, migration:)

      nav_menu_links.each do |nav_menu_link|
        import_from_migration(nav_menu_link, migration.context, migration, existing_links)
      rescue => e
        migration.add_import_warning(t("#migration.custom_link_type", "Custom Link"), nav_menu_link[:label].to_s, e)
      end
    end

    def self.existing_links_by_migration_id(nav_menu_links:, migration:)
      migration_ids = nav_menu_links.filter_map { |link| link[:migration_id] }.uniq

      NavMenuLink.active.where(
        course: migration.context,
        course_nav: true,
        migration_id: migration_ids
      ).index_by(&:migration_id)
    end

    def self.import_from_migration(hash, course, migration, existing_links)
      migration_id = hash[:migration_id]

      item = existing_links[migration_id]

      # For now, NavMenuLinks are immutable, so we don't update old ones.
      # This could change in the future.
      unless item
        url = hash[:url].to_s.strip
        label = hash[:label].to_s.strip
        item = NavMenuLink.create!(course:, migration_id:, course_nav: true, url:, label:)
      end

      migration.add_imported_item(item)
      item
    end
  end
end
