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

class AddClosedToAccessibilityIssuesWorkflowState < ActiveRecord::Migration[8.0]
  tag :predeploy
  disable_ddl_transaction!

  def rename_check_constraint(table, from:, to:)
    reversible do |dir|
      dir.up do
        execute("ALTER TABLE #{connection.quote_table_name(table)} RENAME CONSTRAINT #{from} TO #{to}")
      end
      dir.down do
        execute("ALTER TABLE #{connection.quote_table_name(table)} RENAME CONSTRAINT #{to} TO #{from}")
      end
    end
  end

  def up
    # Rename existing constraint to old if it exists
    unless check_constraint_exists?(:accessibility_issues, name: "chk_workflow_state_enum_old")
      rename_check_constraint :accessibility_issues, from: "chk_workflow_state_enum", to: "chk_workflow_state_enum_old"
    end

    # Add the new constraint without validation (includes 'closed')
    add_check_constraint :accessibility_issues, "workflow_state IN ('active', 'resolved', 'dismissed', 'closed')", name: "chk_workflow_state_enum", validate: false

    # Validate the new constraint
    validate_constraint :accessibility_issues, :chk_workflow_state_enum

    # Remove the old constraint
    remove_check_constraint :accessibility_issues, name: "chk_workflow_state_enum_old"
  end

  def down
    # Rename existing constraint to old if it exists
    unless check_constraint_exists?(:accessibility_issues, name: "chk_workflow_state_enum_old")
      rename_check_constraint :accessibility_issues, from: "chk_workflow_state_enum", to: "chk_workflow_state_enum_old"
    end

    # Add the old constraint without validation (without 'closed')
    add_check_constraint :accessibility_issues, "workflow_state IN ('active', 'resolved', 'dismissed')", name: "chk_workflow_state_enum", validate: false

    # Validate the old constraint
    validate_constraint :accessibility_issues, :chk_workflow_state_enum

    # Remove the renamed constraint
    remove_check_constraint :accessibility_issues, name: "chk_workflow_state_enum_old"
  end
end
