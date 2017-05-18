#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AddDataExport < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :data_exports do |t|
      t.integer :user_id, :limit => 8
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :data_exports, [:context_id, :context_type]
    add_index :data_exports, :user_id
    add_foreign_key :data_exports, :users
  end

  def self.down
    drop_table :data_exports
  end
end
