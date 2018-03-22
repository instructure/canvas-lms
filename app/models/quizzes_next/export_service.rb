# Copyright (C) 2018 - present Instructure, Inc.
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

module QuizzesNext
  class ExportService
    class << self
      def applies_to_course?(course)
        QuizzesNext::Service.enabled_in_context?(course)
      end

      def begin_export(course, _)
        assignments = QuizzesNext::Service.active_lti_assignments_for_course(course)
        return if assignments.empty?

        {
          "original_course_uuid": course.uuid,
          "assignments": assignments.map do |assignment|
            {
              "original_resource_link_id": assignment.lti_resource_link_id,
              "$canvas_assignment_id": assignment.id # transformed to new id
            }
          end
        }
      end

      def export_completed?(_)
        true
      end

      def retrieve_export(export_data)
        export_data
      end

      def send_imported_content(new_course, imported_content)
        imported_content[:assignments].each do |assignment|
          next if QuizzesNext::Service.assignment_not_in_export?(assignment)
          Canvas::LiveEvents.quizzes_next_quiz_duplicated(
            {
              original_course_uuid: imported_content[:original_course_uuid],
              new_course_uuid: new_course.uuid,
              original_resource_link_id: assignment[:original_resource_link_id],
              new_resource_link_id: Assignment.find(assignment[:$canvas_assignment_id]).lti_resource_link_id
            }
          )
        end
      end

      def import_completed?(_)
        true
      end
    end
  end
end
