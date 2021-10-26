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

require_dependency 'importers'

module Importers
  class PacePlanImporter < Importer
    self.item_class = PacePlan

    def self.process_migration(data, migration)
      pace_plans = data['pace_plans'] || []
      pace_plans.each do |pace_plan|
        self.import_from_migration(pace_plan, migration.context, migration)
      end
    end

    def self.import_from_migration(hash, context, migration)
      hash = hash.with_indifferent_access
      return unless migration.import_object?('pace_plans', hash[:migration_id])

      pace_plan = context.pace_plans.primary.where(workflow_state: hash[:workflow_state]).take
      pace_plan ||= context.pace_plans.create

      pace_plan.workflow_state = hash[:workflow_state]
      pace_plan.end_date = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_date])
      pace_plan.published_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:published_at])
      pace_plan.exclude_weekends = hash[:exclude_weekends]
      pace_plan.hard_end_dates = hash[:hard_end_dates]
      pace_plan.save!

      # preload mapping from content tag migration id to id
      module_items_by_migration_id = context.context_module_tags.not_deleted
                                            .select(:id, :migration_id)
                                            .index_by(&:migration_id)

      hash[:module_items].each do |pp_module_item|
        module_item_id = module_items_by_migration_id[pp_module_item[:module_item_migration_id]]&.id
        if module_item_id
          pace_plan_module_item = pace_plan.pace_plan_module_items.find_or_create_by(module_item_id: module_item_id)
          pace_plan_module_item.duration = pp_module_item[:duration]
          pace_plan_module_item.save!
        end
      end
    end
  end
end
