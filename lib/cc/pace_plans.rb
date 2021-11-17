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
module CC
  module PacePlans
    def create_pace_plans(document = nil)
      return nil unless @course.pace_plans.primary.not_deleted.any?

      if document
        meta_file = nil
        rel_path = nil
      else
        meta_file = File.new(File.join(@canvas_resource_dir, CCHelper::PACE_PLANS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::PACE_PLANS)
        document = Builder::XmlMarkup.new(:target => meta_file, :indent => 2)
      end

      document.instruct!
      document.pace_plans(
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |pace_plans_node|
        @course.pace_plans.primary.not_deleted.each do |pace_plan|
          next unless export_object?(pace_plan)

          pace_plans_node.pace_plan(identifier: create_key(pace_plan)) do |pace_plan_node|
            pace_plan_node.workflow_state pace_plan.workflow_state
            pace_plan_node.end_date CCHelper::ims_date(pace_plan.end_date) if pace_plan.end_date
            pace_plan_node.published_at CCHelper::ims_datetime(pace_plan.published_at) if pace_plan.published_at
            pace_plan_node.exclude_weekends pace_plan.exclude_weekends
            pace_plan_node.hard_end_dates pace_plan.hard_end_dates
            pace_plan_node.module_items do |module_items_node|
              pace_plan.pace_plan_module_items.ordered.each do |pace_plan_module_item|
                module_items_node.module_item do |module_item_node|
                  module_item_node.duration pace_plan_module_item.duration
                  module_item_node.module_item_identifierref create_key(pace_plan_module_item.module_item)
                end
              end
            end
          end
        end
      end

      meta_file.close if meta_file
      rel_path
    end
  end
end
