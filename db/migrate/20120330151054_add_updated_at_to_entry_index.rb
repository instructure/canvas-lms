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

class AddUpdatedAtToEntryIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_topic_materialized_views, :generation_started_at, :timestamp
    add_index :discussion_entries, [:discussion_topic_id, :updated_at, :created_at], :name => "index_discussion_entries_for_topic"
    remove_index :discussion_entries, :name => "index_discussion_entries_on_discussion_topic_id"
  end

  def self.down
    remove_column :discussion_topic_materialized_views, :generation_started_at
    add_index :discussion_entries, [:discussion_topic_id], :name => "index_discussion_entries_on_discussion_topic_id"
    remove_index :discussion_entries, :name => "index_discussion_entries_for_topic"
  end
end
