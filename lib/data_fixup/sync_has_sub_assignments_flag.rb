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

module DataFixup
  module SyncHasSubAssignmentsFlag
    def self.run
      # Assignments flagged with has_sub_assignments as true but with no active sub-assignments
      Assignment.active.has_sub_assignments.find_ids_in_batches(batch_size: 10_000) do |assignment_ids_chunk|
        Assignment.where(id: assignment_ids_chunk)
                  .where.not(has_sub_assignments: false)
                  .where(<<~SQL.squish)
                    NOT EXISTS (
                      SELECT 1
                        FROM #{SubAssignment.quoted_table_name} AS sub_a
                       WHERE sub_a.parent_assignment_id = assignments.id
                         AND sub_a.workflow_state <> 'deleted'
                         AND sub_a.type = 'SubAssignment'
                    )
                  SQL
                  .update_all(has_sub_assignments: false)
      end

      # Assignments flagged has_sub_assignments as false but that actually have active sub-assignments
      Assignment.active.has_no_sub_assignments.find_ids_in_batches(batch_size: 10_000) do |assignment_ids_chunk|
        Assignment.where(id: assignment_ids_chunk)
                  .where.not(has_sub_assignments: true)
                  .where(<<~SQL.squish)
                    EXISTS (
                      SELECT 1
                        FROM #{SubAssignment.quoted_table_name} AS sub_a
                       WHERE sub_a.parent_assignment_id = assignments.id
                         AND sub_a.workflow_state <> 'deleted'
                         AND sub_a.type = 'SubAssignment'
                    )
                  SQL
                  .update_all(has_sub_assignments: true)
      end
    end
  end
end
