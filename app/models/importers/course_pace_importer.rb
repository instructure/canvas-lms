# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
  class CoursePaceImporter < Importer
    self.item_class = CoursePace

    def self.process_migration(data, migration)
      course_paces = data["course_paces"] || []
      course_paces.each do |course_pace|
        import_from_migration(course_pace, migration.context, migration)
      end
    end

    def self.import_from_migration(hash, context, migration)
      hash = hash.with_indifferent_access
      return unless migration.import_object?("course_paces", hash[:migration_id])

      course_pace = context.course_paces.primary.find_by(workflow_state: hash[:workflow_state])
      course_pace ||= context.course_paces.create

      course_pace.migration_id = hash[:migration_id]
      course_pace.mark_as_importing! migration
      course_pace.workflow_state = hash[:workflow_state]
      course_pace.end_date = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_date])
      course_pace.published_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:published_at])
      course_pace.exclude_weekends = hash[:exclude_weekends]
      course_pace.hard_end_dates = hash[:hard_end_dates]
      course_pace.save!

      # preload mapping from content tag migration id to id
      module_items_by_migration_id = context.context_module_tags.not_deleted
                                            .select(:id, :migration_id)
                                            .index_by(&:migration_id)

      skip_pace_items = migration.for_master_course_import? && # blueprint sync
                        migration.master_course_subscription.content_tag_for(course_pace).downstream_changes.include?("duration") && # changed downstream
                        !course_pace.child_content_restrictions[:content] # not locked

      unless skip_pace_items
        hash[:module_items].each do |pp_module_item|
          module_item = module_items_by_migration_id[pp_module_item[:module_item_migration_id]]
          next unless module_item

          course_pace_module_item = course_pace.course_pace_module_items.find_or_create_by(module_item_id: module_item.id)
          course_pace_module_item.migration_id = pp_module_item[:pace_item_migration_id]
          course_pace_module_item.duration = pp_module_item[:duration]
          course_pace_module_item.save!

          migration.add_imported_item(course_pace_module_item)
        end
      end
    end
  end
end
