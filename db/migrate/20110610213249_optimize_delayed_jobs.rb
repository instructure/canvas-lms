#
# Copyright (C) 2011 - present Instructure, Inc.
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

class OptimizeDelayedJobs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    create_table :failed_jobs do |t|
      t.integer  "priority",    :default => 0
      t.integer  "attempts",    :default => 0
      t.string   "handler",     :limit => 512000
      t.integer  "original_id", :limit => 8
      t.text     "last_error"
      t.string   "queue"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "tag"
      t.integer  "max_attempts"
      t.string   "strand"
    end

    remove_index :delayed_jobs, :name => 'get_delayed_jobs_index'
    remove_index :delayed_jobs, [:strand]

    add_index :delayed_jobs, %w(run_at queue locked_at strand priority), :name => 'index_delayed_jobs_for_get_next'
    add_index :delayed_jobs, %w(strand id), :name => 'index_delayed_jobs_on_strand'

    # move all failed jobs to the new failed table
    Delayed::Backend::ActiveRecord::Job.where("failed_at IS NOT NULL").find_each do |job|
      job.fail! unless job.on_hold?
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
