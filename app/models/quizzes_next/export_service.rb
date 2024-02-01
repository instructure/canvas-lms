# frozen_string_literal: true

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

      def begin_export(course, opts)
        selected_assignment_ids = nil
        if opts[:selective]
          selected_assignment_ids = opts[:exported_assets].filter_map { |asset| (match = asset.match(/assignment_(\d+)/)) && match[1] }
          return unless selected_assignment_ids.any?
        end
        assignments = QuizzesNext::Service.active_lti_assignments_for_course(course, selected_assignment_ids:)
        return if assignments.empty?

        {
          original_course_uuid: course.uuid,
          assignments: assignments.map do |assignment|
            {
              original_resource_link_id: assignment.lti_resource_link_id,
              original_assignment_id: assignment.id,
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

      def send_imported_content(new_course, content_migration, imported_content)
        send_quizzes_next_quiz_duplicated = false
        original_course = Course.find_by(uuid: imported_content[:original_course_uuid])
        return unless original_course

        imported_content[:assignments].each do |assignment|
          next if QuizzesNext::Service.assignment_not_in_export?(assignment)
          next unless QuizzesNext::Service.assignment_duplicated?(assignment)

          old_assignment_id = assignment.fetch(:original_assignment_id)
          old_assignment = Assignment.find_by(id: old_assignment_id, context_id: original_course.id)
          next unless old_assignment

          new_assignment_id = assignment.fetch(:$canvas_assignment_id)
          new_assignment = Assignment.find(new_assignment_id)
          next unless new_assignment.created_at > content_migration.started_at # no more recopies

          send_quizzes_next_quiz_duplicated = true

          new_assignment.skip_downstream_changes! # don't let these updates prevent future blueprint syncs
          new_assignment.duplicate_of = old_assignment
          new_assignment.workflow_state = "duplicating"
          new_assignment.duplication_started_at = Time.zone.now
          new_assignment.save!
        end

        if send_quizzes_next_quiz_duplicated
          is_blueprint_sync =
            content_migration.migration_type == "master_course_import" &&
            MasterCourses::ChildSubscription.is_child_course?(new_course)

          remove_alignments = content_migration.migration_type == "course_copy_importer" && content_migration.copy_options.exclude?(:everything) && content_migration.copy_options.exclude?(:all_learning_outcomes)
          Canvas::LiveEvents.quizzes_next_quiz_duplicated(
            {
              original_course_uuid: imported_content[:original_course_uuid],
              new_course_uuid: new_course.uuid,
              new_course_resource_link_id: new_course.lti_context_id,
              domain: new_course.root_account&.domain(ApplicationController.test_cluster_name),
              new_course_name: new_course.name,
              created_on_blueprint_sync: is_blueprint_sync,
              resource_map_url: content_migration.asset_map_url(generate_if_needed: true),
              remove_alignments:,
              status: "duplicating"
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
