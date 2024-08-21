# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class DropUserNoteEntities < ActiveRecord::Migration[7.0]
  tag :postdeploy

  def change
    remove_column :accounts, :enable_user_notes, type: :boolean, default: false
    remove_column :users, :last_user_note, type: :timestamp
    remove_column :conversation_batches, :generate_user_note, type: :boolean

    drop_table :user_notes do |t|
      t.references :user, foreign_key: true, index: false
      t.text :note
      t.string :title, limit: 255
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :workflow_state, default: "active", null: false, limit: 255
      t.timestamp :deleted_at
      t.timestamps precision: nil
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.replica_identity_index
      t.index [:user_id, :workflow_state]
    end
  end
end
