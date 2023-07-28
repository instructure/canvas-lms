# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class DropContextExternalToolAssignmentLookups < ActiveRecord::Migration[7.0]
  tag :postdeploy

  def up
    drop_table :context_external_tool_assignment_lookups, if_exists: true
  end

  def down
    create_table :context_external_tool_assignment_lookups do |t|
      t.integer :assignment_id, limit: 8, null: false
      t.integer :context_external_tool_id, limit: 8, null: false
    end
    add_index :context_external_tool_assignment_lookups, [:context_external_tool_id, :assignment_id], unique: true, name: "tool_to_assign"
    add_index :context_external_tool_assignment_lookups, :assignment_id
    add_foreign_key :context_external_tool_assignment_lookups, :assignments
    add_foreign_key :context_external_tool_assignment_lookups, :context_external_tools
  end
end
