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

class AddDelayedJobsShardIdToShards < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # this is out of order with respect to its original version, so check if it has
    # already been run
    return if connection.column_exists?(:switchman_shards, :delayed_jobs_shard_id)
    add_column :switchman_shards, :delayed_jobs_shard_id, :integer, :limit => 8
    add_foreign_key :switchman_shards, :switchman_shards, :column => :delayed_jobs_shard_id
  end

  def self.down
    remove_column :switchman_shards, :delayed_jobs_shard_id
  end
end
