#
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

class CleanUpAssignmentOverrides < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::RemoveOrphanedAssignmentOverrideStudents.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOW_PRIORITY,
      max_attempts: 1,
      n_strand: 'long_datafixups'
    )

    # this fix is fast enough to run synchronously, without requiring a multi-deploy rollout of the check constraint
    DataFixup::RemoveInvalidAssignmentOverrides.run
    # we will break the constraint creation and validation into separate queries to reduce time spent in ex-lock
    execute(<<-SQL)
      ALTER TABLE #{AssignmentOverride.quoted_table_name}
      ADD CONSTRAINT require_quiz_or_assignment
      CHECK (workflow_state='deleted' OR quiz_id IS NOT NULL OR assignment_id IS NOT NULL)
      NOT VALID
    SQL
    execute("ALTER TABLE #{AssignmentOverride.quoted_table_name} VALIDATE CONSTRAINT require_quiz_or_assignment")

  end

  def self.down
    execute(<<-SQL)
      ALTER TABLE #{AssignmentOverride.quoted_table_name}
      DROP CONSTRAINT IF EXISTS require_quiz_or_assignment
    SQL
  end
end
