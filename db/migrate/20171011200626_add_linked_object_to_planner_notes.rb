#
# Copyright (C) 2017 - present Instructure, Inc.
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
#

class AddLinkedObjectToPlannerNotes < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :planner_notes, :linked_object_type, :string
    add_column :planner_notes, :linked_object_id, :integer, limit: 8
    add_index :planner_notes, [:user_id, :linked_object_id, :linked_object_type], algorithm: :concurrently,
      where: "linked_object_id IS NOT NULL AND workflow_state<>'deleted'", unique: true,
      name: 'index_planner_notes_on_user_id_and_linked_object'
  end
end
