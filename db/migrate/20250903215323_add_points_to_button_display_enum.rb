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

class AddPointsToButtonDisplayEnum < ActiveRecord::Migration[7.2]
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
    # Make sure the renamed constraint does not exist and rename the current constraint to avoid naming conflicts
    unless check_constraint_exists?(:rubrics, name: "chk_button_display_enum_old")
      rename_check_constraint :rubrics, from: "chk_button_display_enum", to: "chk_button_display_enum_old"
    end

    # Add the new constraint without validation
    add_check_constraint :rubrics, "button_display IN ('numeric', 'emoji', 'letter', 'points')", name: "chk_button_display_enum", validate: false

    # Validate the new constraint
    validate_constraint :rubrics, :chk_button_display_enum

    # Remove the old constraint
    remove_check_constraint :rubrics, name: "chk_button_display_enum_old"
  end

  def down
    # Make sure the renamed constraint does not exist and rename the current constraint to avoid naming conflicts
    unless check_constraint_exists?(:rubrics, name: "chk_button_display_enum_old")
      rename_check_constraint :rubrics, from: "chk_button_display_enum", to: "chk_button_display_enum_old"
    end
    # Add the old constraint without validation
    add_check_constraint :rubrics, "button_display IN ('numeric', 'emoji', 'letter')", name: "chk_button_display_enum", validate: false

    # Validate the old constraint
    validate_constraint :rubrics, :chk_button_display_enum

    # Remove the renamed constraint
    remove_check_constraint :rubrics, name: "chk_button_display_enum_old"
  end
end
