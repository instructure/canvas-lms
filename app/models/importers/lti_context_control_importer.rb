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
        return [] unless data["lti_context_controls"].present?

        controls = data["lti_context_controls"]
        preloaded_tools = migration.context.context_external_tools
                                   .where(migration_id: controls.pluck("deployment_migration_id").compact)
                                   .group_by(&:migration_id)
        controls.each do |control|
          tool = preloaded_tools[control["deployment_migration_id"]]&.first
          next unless import_control?(control, tool, migration)

          import_from_migration(control, tool, migration.context, migration)
        rescue => e
          migration.add_error(t("#migration.lti_context_control_type", "LTI Context Control"),
                              control[:migration_id],
                              e)
        end
      end

      private

      def import_from_migration(hash, matching_tool, context, migration)
        Lti::ContextControlService
          .create_or_update({
                              course_id: context.id,
                              deployment_id: matching_tool.id,
                              registration_id: matching_tool.lti_registration_id || matching_tool.developer_key.lti_registration_id,
                              workflow_state: "active",
                              available: hash["available"],
                              updated_by: migration.user,
                            },
                            comment: "Imported from migration")
      end

      def import_control?(control, matching_tool, migration)
        # Only controls that are associated with a tool that's also being imported
        # are allowed to be imported. This is a bit of a workaround/hack around permissions,
        # as it ensures we don't suddenly break everybody's workflow of copying tools around
        # while still making sure that teachers can't modify controls associated with
        # account/sub-account level tools.
        control["deployment_migration_id"].present? &&
          matching_tool&.active? &&
          (migration.import_object?("context_external_tools", control["deployment_migration_id"]) ||
            migration.import_object?("external_tools", control["deployment_migration_id"]))
      end
    end
  end
end
