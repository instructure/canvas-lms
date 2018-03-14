#
# Copyright (C) 2013 - present Instructure, Inc.
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

class CreateOneTimePasswords < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :one_time_passwords do |t|
      t.integer :user_id, limit: 8, null: false
      t.string :code, null: false
      t.boolean :used, null: false, default: false
      t.timestamps null: false
    end
    add_index :one_time_passwords, [:user_id, :code], unique: true
    add_foreign_key :one_time_passwords, :users
  end
end
