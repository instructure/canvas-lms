# frozen_string_literal: true

#
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

class EnsureUniqueAccountUsers < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    DataFixup::DeleteDuplicateRows.run(AccountUser, :user_id, :role_id, :account_id)
    add_index :account_users, %i[user_id role_id account_id], unique: true, algorithm: :concurrently, if_not_exists: true
    remove_index :account_users, [:user_id], algorithm: :concurrently, if_exists: true
  end
end
