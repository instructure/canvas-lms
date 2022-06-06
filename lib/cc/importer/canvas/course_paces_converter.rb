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
  module CoursePacesConverter
    include CC::Importer

    def convert_course_paces(doc)
      course_paces = []
      return course_paces unless doc

      doc.css("course_pace").each do |course_pace_node|
        course_pace = {}
        course_pace[:migration_id] = course_pace_node["identifier"]
        course_pace[:workflow_state] = get_node_val(course_pace_node, "workflow_state")
        course_pace[:end_date] = get_time_val(course_pace_node, "end_date")
        course_pace[:published_at] = get_time_val(course_pace_node, "published_at")
        course_pace[:exclude_weekends] = get_bool_val(course_pace_node, "exclude_weekends")
        course_pace[:hard_end_dates] = get_bool_val(course_pace_node, "hard_end_dates")

        course_pace[:module_items] = []
        course_pace_node.css("module_item").each do |item_node|
          item = {}
          item[:duration] = get_int_val(item_node, "duration")
          item[:module_item_migration_id] = get_node_val(item_node, "module_item_identifierref")
          item[:pace_item_migration_id] = get_node_val(item_node, "pace_item_identifier")
          course_pace[:module_items] << item
        end

        course_paces << course_pace
      end

      course_paces
    end
  end
end
