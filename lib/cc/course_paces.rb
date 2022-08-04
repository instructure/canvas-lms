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
  module CoursePaces
    def create_course_paces(document = nil)
      return nil unless @course.course_paces.primary.not_deleted.any?

      if document
        meta_file = nil
        rel_path = nil
      else
        meta_file = File.new(File.join(@canvas_resource_dir, CCHelper::COURSE_PACES), "w")
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::COURSE_PACES)
        document = Builder::XmlMarkup.new(target: meta_file, indent: 2)
      end

      document.instruct!
      document.course_paces(
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |course_paces_node|
        @course.course_paces.primary.not_deleted.each do |course_pace|
          next unless export_object?(course_pace)

          course_paces_node.course_pace(identifier: create_key(course_pace)) do |course_pace_node|
            course_pace_node.workflow_state course_pace.workflow_state
            course_pace_node.end_date CCHelper.ims_date(course_pace.end_date) if course_pace.end_date
            course_pace_node.published_at CCHelper.ims_datetime(course_pace.published_at) if course_pace.published_at
            course_pace_node.exclude_weekends course_pace.exclude_weekends
            course_pace_node.hard_end_dates course_pace.hard_end_dates
            add_exported_asset(course_pace)
            course_pace_node.module_items do |module_items_node|
              course_pace.course_pace_module_items.ordered.each do |course_pace_module_item|
                module_items_node.module_item do |module_item_node|
                  module_item_node.duration course_pace_module_item.duration
                  module_item_node.module_item_identifierref create_key(course_pace_module_item.module_item)
                  module_item_node.pace_item_identifier create_key(course_pace_module_item)
                end
              end
            end
          end
        end
      end

      meta_file&.close
      rel_path
    end
  end
end
