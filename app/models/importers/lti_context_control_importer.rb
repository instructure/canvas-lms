# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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
  class LtiContextControlImporter < Importer
    self.item_class = Lti::ContextControl

    class << self
      def process_migration(data, migration)
        controls = data["lti_context_controls"] || []
        controls.each do |control|
          next unless import_control?(control, migration)

          import_from_migration(control, migration.context, migration)
        rescue => e
          migration.add_import_warning(t("#migration.lti_context_control_type", "LTI Context Control"),
                                       control[:url],
                                       e)
        end
      end

      private

      def import_from_migration(hash, context, migration)
        # We have to do URL matching here, as it's possible that this course
        # copy is across different institutions, so a matching tool wouldn't
        # have the same ID as the one in the source course. We can skip a lot of
        # the work though if the preferred_tool is available for use in this
        # context.
        # We have to ignore availability checks as it's possible that this context control
        # is going to enable the tool in the course, but otherwise the tool isn't available,
        # either because it was just copied or it's set to not available at a higher context.
        matching_tool = Lti::ToolFinder.from_url(hash["deployment_url"],
                                                 context,
                                                 only_1_3: true,
                                                 preferred_tool_id: hash["preferred_deployment_id"],
                                                 check_availability: false)

        if matching_tool.nil?
          migration.add_import_warning(t("#migration.lti_context_control_type", "LTI Context Control"),
                                       hash["deployment_url"],
                                       t("#migration.lti_context_control_no_tool",
                                         "Unable to find a matching tool for the context control. Please ensure that a tool with a matching URL is available in the course."))
          return
        end

        if Lti::ContextControl.active.where(course: context, deployment: matching_tool, registration: matching_tool.lti_registration).exists?
          migration.add_import_warning(t("#migration.lti_context_control_type", "LTI Context Control"),
                                       hash["deployment_url"],
                                       t("#migration.lti_context_control_exists",
                                         "A context control for the tool with the given URL already exists. Skipping import for this control."))
          return
        end

        registration_id = matching_tool.lti_registration.id || matching_tool.developer_key.lti_registration.id

        Lti::ContextControlService.create_or_update(course_id: context.id,
                                                    deployment_id: matching_tool.id,
                                                    registration_id:,
                                                    workflow_state: "active",
                                                    available: hash["available"],
                                                    updated_by: migration.user)
      end

      def import_control?(control, migration)
        if control["deployment_migration_id"].present?
          # The tool is being imported as well, so we can use the migration ID
          # to check if we should import this control.
          migration.import_object?("context_external_tools", control["deployment_migration_id"])
        else
          # The control was not associated with a course level tool, so default to course
          # settings.
          migration.import_object?("course_settings", "")
        end
      end
    end
  end
end
