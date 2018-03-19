#
# Copyright (C) 2018 - present Instructure, Inc.
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

class CreateDeveloperKeyAccountBindings < ActiveRecord::Migration[5.0]
  tag :predeploy

  def up
    return if table_exists? :developer_key_account_bindings
    create_table :developer_key_account_bindings do |t|
      t.integer :account_id, limit: 8, null: false
      t.integer :developer_key_id, limit: 8, null: false
      t.string :workflow_state, null: false
      t.timestamps null: true
    end

    add_foreign_key :developer_key_account_bindings, :accounts
    add_foreign_key :developer_key_account_bindings, :developer_keys

    add_index :developer_key_account_bindings, :developer_key_id
    add_index :developer_key_account_bindings, %i(account_id developer_key_id), name: :index_dev_key_bindings_on_account_id_and_developer_key_id, unique: true
  end

  def down
    drop_table :developer_key_account_bindings
  end
end
