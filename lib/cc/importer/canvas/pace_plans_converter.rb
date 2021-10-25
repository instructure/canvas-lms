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
#
module CC::Importer::Canvas
  module PacePlansConverter
    include CC::Importer

    def convert_pace_plans(doc)
      pace_plans = []
      return pace_plans unless doc

      doc.css('pace_plan').each do |pace_plan_node|
        pace_plan = {}
        pace_plan[:migration_id] = pace_plan_node['identifier']
        pace_plan[:workflow_state] = get_node_val(pace_plan_node, 'workflow_state')
        pace_plan[:end_date] = get_time_val(pace_plan_node, 'end_date')
        pace_plan[:published_at] = get_time_val(pace_plan_node, 'published_at')
        pace_plan[:exclude_weekends] = get_bool_val(pace_plan_node, 'exclude_weekends')
        pace_plan[:hard_end_dates] = get_bool_val(pace_plan_node, 'hard_end_dates')

        pace_plan[:module_items] = []
        pace_plan_node.css('module_item').each do |item_node|
          item = {}
          item[:duration] = get_int_val(item_node, 'duration')
          item[:module_item_migration_id] = get_node_val(item_node, 'module_item_identifierref')
          pace_plan[:module_items] << item
        end

        pace_plans << pace_plan
      end

      pace_plans
    end
  end
end
