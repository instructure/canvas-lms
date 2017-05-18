#
# Copyright (C) 2012 - present Instructure, Inc.
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

class CreateRoles < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :enrollments, :role_name, :string

    create_table :roles do |t|
      t.string :name, :null => false
      t.string :base_role_type, :null => false
      t.integer :account_id, :null => false, :limit => 8
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end
    add_foreign_key :roles, :accounts
    add_index :roles, [:name], :name => "index_roles_on_name"
    add_index :roles, [:account_id], :name => "index_roles_on_account_id"
  end

  def self.down
    remove_column :enrollments, :role_name

    drop_table :roles
  end
end
