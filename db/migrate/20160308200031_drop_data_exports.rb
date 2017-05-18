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

class DropDataExports < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :data_exports
  end

  def down
    create_table :data_exports do |t|
      t.integer :user_id, :limit => 8, :null => false
      t.integer :context_id, :limit => 8, :null => false
      t.string :context_type, :null => false
      t.string :workflow_state, :null => false
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :data_exports, [:context_id, :context_type]
    add_index :data_exports, :user_id
    add_foreign_key :data_exports, :users
  end
end
