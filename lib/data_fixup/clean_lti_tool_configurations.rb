# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class DataFixup::CleanLtiToolConfigurations < CanvasOperations::DataFixup
  self.mode = :individual_record
  self.progress_tracking = false
  self.record_changes = true

  scope do
    Lti::ToolConfiguration.all
  end

  def process_record(record)
    record.valid?
    return unless record.changed?

    record.save!
    record.global_id
  rescue => e
    Canvas::Errors.capture(e,
                           {
                             tags: {
                               operation: self.class.operation_name,
                               global_tool_configuration_id: record.global_id,
                             }
                           },
                           :error)
    log_message(
      "Error cleaning Lti::ToolConfiguration #{record.global_id} " \
      "on shard #{Shard.current.id}: #{e.message}",
      level: :error
    )
    # We specifically don't re-raise so other records in this batch
    # continue to get processed.
  end
end
