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

class CleanupDelayedJobsIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    case connection.adapter_name
    when 'PostgreSQL'
      # "nulls first" syntax is postgresql specific, and allows for more
      # efficient querying for the next job
      connection.execute("CREATE INDEX get_delayed_jobs_index ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} (priority, run_at, failed_at nulls first, locked_at nulls first, queue)")
    else
      add_index :delayed_jobs, %w(priority run_at locked_at failed_at queue), :name => 'get_delayed_jobs_index'
    end

    # unused indexes
    remove_index :delayed_jobs, :name => 'delayed_jobs_queue'
    remove_index :delayed_jobs, :name => 'delayed_jobs_priority'
  end

  def self.down
    remove_index :delayed_jobs, :name => 'get_delayed_jobs_index'
    add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
    add_index :delayed_jobs, [:queue], :name => 'delayed_jobs_queue'
  end
end
