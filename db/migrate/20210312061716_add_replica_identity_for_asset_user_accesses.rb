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

class AddReplicaIdentityForAssetUserAccesses < ActiveRecord::Migration[6.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_replica_identity 'AssetUserAccess', :root_account_id, 0
    remove_index :asset_user_accesses, column: :root_account_id, if_exists: true
  end

  def down
    add_index :asset_user_accesses, :root_account_id, algorithm: :concurrently, if_not_exists: true
    remove_replica_identity 'AssetUserAccess'
    change_column_null :asset_user_accesses, :root_account_id, true
  end
end
