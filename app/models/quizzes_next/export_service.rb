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
          "original_course_id": course.id,
          "assignments": assignments.map do |assignment|
            {
              "original_link_id": assignment.lti_resource_link_id,
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
        # TODO: emit live events here with the imported data
        #   - This gets called after the export is complete and has been imported into canvas
        #
        # imported_content["assignments"].each do |assignment|
        #   emit_live_event(
        #     body: {
        #       "original_course_id" => imported_content["original_course_id"],
        #       "new_course_id" => new_course.id
        #       "original_resource_link_id" => assigment["original_link_id"],
        #         - We want to send this so that quizzes next can identify the old quiz to copy
        #
        #       "new_resource_link_id" => Assignment.find(assignment["$canvas_assignment_id"]).resource_link_id
        #         - We want to send this so that quizzes next can link the new quiz to the new canvas assignment
        #     }
        #   )
        # end
      end

      def import_completed?(_)
        true
      end
    end
  end
end
