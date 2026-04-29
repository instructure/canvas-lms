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

    def self.should_process?(data, migration)
      return false unless migration.import_object?("course_settings", "")
      # The above check is not sufficient for blueprint courses; use this check which is the same as that used in CourseContentImporter to determine if tab configuration is imported:
      return false unless data[:course] && data[:course][:tab_configuration].is_a?(Array)
      return false unless migration.context.root_account.feature_enabled?(:nav_menu_links)

      true
    end

    def self.process_migration(data, migration)
      return unless should_process?(data, migration)

      nav_menu_links = (data["nav_menu_links"] || []).map(&:with_indifferent_access)

      if migration.for_master_course_import?
        keep_migration_ids = nav_menu_links.pluck(:migration_id).compact
        delete_orphaned_master_course_links(course: migration.context, keep_migration_ids:)
      end

      return if nav_menu_links.blank?

      # Preload existing links to avoid N+1 queries
      existing_links = existing_links_by_migration_id(nav_menu_links:, migration:)

      nav_menu_links.each do |nav_menu_link|
        import_from_migration(nav_menu_link, migration.context, migration, existing_links)
      rescue => e
        # Unexpected errors
        er = Canvas::Errors.capture_exception(:import_nav_menu_links, e)[:error_report]
        error_message = t(
          "#migration.custom_link_import_failed",
          "Custom Link could not be imported: %{link_label}",
          link_label: trunc_str(nav_menu_link[:label].to_s)
        )
        migration.add_warning(error_message, error_report_id: er)
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
        # Convert migration ID placeholders to actual URLs
        raw_url = hash[:url].to_s.strip
        label = hash[:label].to_s.strip
        converted_url = migration.convert_single_link(raw_url)

        if converted_url.nil?
          add_unresolvable_warning(migration:, label:, raw_url:)
          return nil
        end

        begin
          item = NavMenuLink.create!(course:, migration_id:, course_nav: true, url: converted_url, label:)
        rescue ActiveRecord::RecordInvalid => e
          add_invalid_url_error(migration:, label:, converted_url:, err: e)
          return nil
        end
      end

      migration.add_imported_item(item)
      item
    end

    def self.add_unresolvable_warning(migration:, label:, raw_url:)
      error_message = t(
        "#migration.custom_link_invalid_url",
        "The link labeled %{link_label} was not copied because the resource it links to was not found in the new course. To link to this resource, add it manually from the navigation tab in Course Settings.",
        link_label: trunc_str(label)
      )
      migration.add_warning(error_message)
    end

    def self.add_invalid_url_error(migration:, label:, converted_url:, err:)
      error_message = t(
        "#migration.custom_link_validation_error",
        "Custom Link could not be imported: %{link_label} (URL: %{url}) - %{validation_errors}",
        link_label: trunc_str(label),
        url: trunc_str(converted_url),
        validation_errors: trunc_str(err.record.errors.full_messages.join(", "), 250)
      )
      migration.add_warning(error_message)
    end

    def self.trunc_str(str, max_length = 150)
      CanvasTextHelper.truncate_text(str, max_length:)
    end

    def self.delete_orphaned_master_course_links(course:, keep_migration_ids:)
      to_delete = NavMenuLink.active
                             .where(course:, course_nav: true)
                             .where("starts_with(migration_id, ?)", MasterCourses::MIGRATION_ID_PREFIX)
                             .where.not(migration_id: keep_migration_ids)
                             .pluck(:id)
      if to_delete.present?
        NavMenuLink.where(id: to_delete)
                   .update_all(workflow_state: :deleted, updated_at: Time.zone.now)
      end
    end
  end
end
