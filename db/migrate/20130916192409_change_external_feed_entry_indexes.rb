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

class ChangeExternalFeedEntryIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :external_feed_entries, :external_feed_id, algorithm: :concurrently
    add_index :external_feed_entries, :uuid, algorithm: :concurrently
    add_index :external_feed_entries, :url, algorithm: :concurrently
    remove_index :external_feed_entries, name: 'external_feed_id_uuid'
    remove_index :external_feed_entries, [:asset_id, :asset_type]
  end

  def self.down
    remove_index :external_feed_entries, :external_feed_id
    remove_index :external_feed_entries, :uuid
    remove_index :external_feed_entries, :url
    add_index :external_feed_entries, [:external_feed_id, :uuid], algorithm: :concurrently, name: 'external_feed_id_uuid'
    add_index :external_feed_entries, [:asset_id, :asset_type], algorithm: :concurrently
  end
end
