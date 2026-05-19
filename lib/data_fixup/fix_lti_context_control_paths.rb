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

# Fixes ContextControl records with invalid path of "."
#
# This can happen when controls are created immediately after account creation
# due to replication lag between primary and secondary databases
class DataFixup::FixLtiContextControlPaths < CanvasOperations::DataFixup
  self.mode = :individual_record
  self.progress_tracking = false

  scope do
    Lti::ContextControl.where(path: ".")
  end

  def process_record(control)
    # Determine the context
    context = if control.account_id
                Account.find_by(id: control.account_id)
              elsif control.course_id
                Course.find_by(id: control.course_id)
              end

    unless context
      Canvas::Errors.capture(
        "FixLtiContextControlPaths: Could not find context for ContextControl #{control.global_id}",
        {
          tags: {
            operation: self.class.operation_name,
            shard_id: Shard.current.id
          }
        },
        :warn
      )
      log_message("Could not find context for ContextControl #{control.global_id}", level: :warn)
      return
    end

    # Recalculate the path
    new_path = Lti::ContextControl.calculate_path(context)

    if new_path == "."
      Canvas::Errors.capture(
        "FixLtiContextControlPaths: Calculated path is still invalid for ContextControl #{control.global_id}",
        {
          tags: {
            operation: self.class.operation_name,
            shard_id: Shard.current.id
          }
        },
        :warn
      )
      log_message("Calculated path is still invalid for ContextControl #{control.global_id}", level: :warn)
      return
    end

    # Update the path if it changed
    if new_path != control.path
      control.update_column(:path, new_path)
      log_message("Fixed ContextControl #{control.global_id} path to '#{new_path}'")
    end
  rescue => e
    Canvas::Errors.capture(
      e,
      {
        tags: {
          operation: self.class.operation_name,
          shard_id: Shard.current.id
        }
      },
      :error
    )
    log_message("Error fixing ContextControl #{control.global_id}: #{e.message}", level: :error)
  end
end
