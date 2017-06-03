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

class CustomGradebookColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :custom_gradebook_columns do |t|
      t.string :title, :null => false
      t.integer :position
      t.string :workflow_state, :default => "active"
      t.integer :course_id, :limit => 8
      t.timestamps null: true
    end
    add_foreign_key :custom_gradebook_columns, :courses, :dependent => true

    create_table :custom_gradebook_column_data do |t|
      t.string :content
      t.integer :user_id, :limit => 8
      t.integer :custom_gradebook_column_id, :limit => 8
    end
    add_foreign_key :custom_gradebook_column_data, :custom_gradebook_columns
    add_foreign_key :custom_gradebook_column_data, :users
    add_index :custom_gradebook_column_data,
      [:custom_gradebook_column_id, :user_id],
      :unique => true,
      :name => "index_custom_gradebook_column_data_unique_column_and_user"
  end

  def self.down
    drop_table :custom_gradebook_column_data
    drop_table :custom_gradebook_columns
  end
end
