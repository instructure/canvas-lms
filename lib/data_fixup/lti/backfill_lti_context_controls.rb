# frozen_string_literal: true

#
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

module DataFixup::Lti::BackfillLtiContextControls
  def self.run
    cached_paths = {}
    ContextExternalTool.lti_1_3.preload(:developer_key)
                       .where.missing(:context_controls)
                       .in_batches do |batch|
      controls = batch.filter_map do |tool|
        # Strangely, even though we have backfilled this column, it still is sometimes
        # nil, even though the tool hasn't been changed since the backfill ran. This
        # handles that strange edge case.
        unless tool.lti_registration_id || tool.developer_key.lti_registration_id
          Sentry.with_scope do |scope|
            scope.set_context("DataFixup::Lti::BackfillLtiContextControls", {
                                global_tool_id: tool.global_id,
                              })
            Sentry.capture_message("Lti::ContextControl not backfilled because no registration ID found", level: :warning)
          end
          next
        end

        control = {
          registration_id: tool.lti_registration_id || tool.developer_key.lti_registration_id,
          available: true,
          deployment_id: tool.id,
          root_account_id: tool.root_account_id,
        }

        if tool.context_type == "Course"
          control[:course_id] = tool.context_id
          control[:account_id] = nil
        else
          control[:account_id] = tool.context_id
          control[:course_id] = nil
        end

        key = [tool.context_id, tool.context_type].cache_key
        control[:path] = (cached_paths[key] ||= Lti::ContextControl.calculate_path(tool.context))
        control
      end

      Lti::ContextControl.insert_all!(controls) if controls.any?
      # Avoid taking too much memory.
      # Some local testing with random IDs 0..2**32 and randomly generated paths with length from
      # 0..100 bytes showed that the memory usage was about 108 MB for 1 million paths
      # (measured using the memory_profiler gem). Most shards have far fewer than 1 million
      # unique contexts, so this should handle most shards quite well.
      cached_paths.clear if cached_paths.size > 1_000_000
    end
  end
end
