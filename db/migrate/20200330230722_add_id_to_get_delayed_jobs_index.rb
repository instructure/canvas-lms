#
# Copyright (C) 2020 - present Instructure, Inc.
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

class AddIdToGetDelayedJobsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def connection
    Delayed::Job.connection
  end

  def up
    rename_index :delayed_jobs, "get_delayed_jobs_index", "get_delayed_jobs_index_old"
    add_index :delayed_jobs, [:priority, :run_at, :id],
      algorithm: :concurrently,
      where: "queue = 'canvas_queue' AND locked_at IS NULL AND next_in_strand",
      name: "get_delayed_jobs_index"
    remove_index :delayed_jobs, name: "get_delayed_jobs_index_old"
  end

  def down
    rename_index :delayed_jobs, "get_delayed_jobs_index", "get_delayed_jobs_index_old"
    add_index :delayed_jobs, [:priority, :run_at],
      algorithm: :concurrently,
      where: "queue = 'canvas_queue' AND locked_at IS NULL AND next_in_strand",
      name: "get_delayed_jobs_index"
    remove_index :delayed_jobs, name: "get_delayed_jobs_index_old"
  end
end
