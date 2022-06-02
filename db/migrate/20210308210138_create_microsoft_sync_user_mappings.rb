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

class CreateMicrosoftSyncUserMappings < ActiveRecord::Migration[6.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    create_table :microsoft_sync_user_mappings do |t|
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.references :user, null: false, foreign_key: true, index: false
      t.string :aad_id
      t.timestamps
      t.index [:user_id, :root_account_id], unique: true, name: "index_microsoft_sync_user_mappings_ra_id_user_id"
      t.index [:root_account_id, :id], unique: true, name: "index_microsoft_sync_user_mappings_replica_identity"
    end

    set_replica_identity(:microsoft_sync_user_mappings, :index_microsoft_sync_user_mappings_replica_identity)
  end

  def down
    drop_table :microsoft_sync_user_mappings
  end
end
