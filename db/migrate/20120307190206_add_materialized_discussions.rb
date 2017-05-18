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

class AddMaterializedDiscussions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # this is fixed in a later migration
    # rubocop:disable Migration/PrimaryKey
    create_table :discussion_topic_materialized_views, :id => false do |t|
      t.integer :discussion_topic_id, :limit => 8
      t.text :json_structure, :limit => 10.megabytes
      t.text :participants_array, :limit => 10.megabytes
      t.text :entry_ids_array, :limit => 10.megabytes

      t.timestamps null: true
    end
    add_index :discussion_topic_materialized_views, :discussion_topic_id, :unique => true, :name => "index_discussion_topic_materialized_views"
  end

  def self.down
    drop_table :discussion_topic_materialized_views
  end
end
