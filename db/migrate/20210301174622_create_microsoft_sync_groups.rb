# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class CreateMicrosoftSyncGroups < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    create_table :microsoft_sync_groups do |t|
      t.references :course, foreign_key: true, index: {unique: true}, null: false

      t.string :workflow_state, null: false, default: 'pending'
      t.string :job_state

      t.datetime :last_synced_at
      t.datetime :last_manually_synced_at
      t.text :last_error

      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.timestamps

      t.index [:root_account_id, :id], unique: true,
        name: 'index_microsoft_sync_groups_replica_identity'
    end
    set_replica_identity(:microsoft_sync_groups, :index_microsoft_sync_groups_replica_identity)
  end

  def down
    drop_table :microsoft_sync_groups
  end
end
