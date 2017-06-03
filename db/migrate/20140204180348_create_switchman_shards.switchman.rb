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

# This migration comes from switchman (originally 20130328212039)
class CreateSwitchmanShards < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    unless table_exists?('switchman_shards')
      create_table :switchman_shards do |t|
        t.string :name
        t.string :database_server_id
        t.boolean :default, :default => false, :null => false
      end
    end

    unless column_exists?(:switchman_shards, :settings)
      add_column :switchman_shards, :settings, :text
    end
  end

  def self.down
    drop_table :switchman_shards
  end
end
