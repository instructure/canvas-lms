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

class DropUserCreationColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :users, :name => 'users_sis_creation'
    remove_column :users, :creation_unique_id
    remove_column :users, :creation_sis_batch_id
    remove_column :users, :creation_email
  end

  def self.down
    add_column :users, :creation_email, :string
    add_column :users, :creation_sis_batch_id, :string
    add_column :users, :creation_unique_id, :string
    add_index :users, [:creation_unique_id, :creation_sis_batch_id], :name => "users_sis_creation"
  end
end
