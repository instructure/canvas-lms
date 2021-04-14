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

class AddReplicaIdentityForUsers < ActiveRecord::Migration[6.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_replica_identity 'User', :root_account_ids, []
    change_column_default :users, :root_account_ids, []
    remove_index :users, column: :root_account_ids, if_exists: true
  end

  def down
    add_index :users, :root_account_ids, algorithm: :concurrently, using: :gin, if_not_exists: true
    remove_replica_identity 'User'
    change_column_null :users, :root_account_ids, true
    change_column_default :users, :root_account_ids, nil
  end
end
