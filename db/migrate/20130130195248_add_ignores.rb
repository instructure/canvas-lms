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

class AddIgnores < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :ignores do |t|
      t.string :asset_type, :null => false
      t.integer :asset_id, :null => false, :limit => 8
      t.integer :user_id, :null => false, :limit => 8
      t.string :purpose, :null => false
      t.boolean :permanent, :null => false, :default => false
      t.timestamps null: true
    end
    add_index :ignores, [:asset_id, :asset_type, :user_id, :purpose], :unique => true, :name => 'index_ignores_on_asset_and_user_id_and_purpose'
    add_foreign_key :ignores, :users
  end

  def self.down
    drop_table :ignores
  end
end
