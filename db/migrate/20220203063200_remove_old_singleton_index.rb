# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

# rubocop:disable Rails/SquishedSQLHeredocs
class RemoveOldSingletonIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  tag :predeploy

  def up
    remove_index :delayed_jobs, name: "index_delayed_jobs_on_singleton_not_running_old", if_exists: true
    remove_index :delayed_jobs, name: "index_delayed_jobs_on_singleton_running_old", if_exists: true
  end

  def down
    rename_index :delayed_jobs, "index_delayed_jobs_on_singleton_not_running", "index_delayed_jobs_on_singleton_not_running_old"
    rename_index :delayed_jobs, "index_delayed_jobs_on_singleton_running", "index_delayed_jobs_on_singleton_running_old"

    # only one job can be queued in a singleton
    add_index :delayed_jobs,
              :singleton,
              where: "singleton IS NOT NULL AND locked_by IS NULL",
              unique: true,
              name: "index_delayed_jobs_on_singleton_not_running",
              algorithm: :concurrently,
              if_not_exists: true

    # only one job can be running for a singleton
    add_index :delayed_jobs,
              :singleton,
              where: "singleton IS NOT NULL AND locked_by IS NOT NULL",
              unique: true,
              name: "index_delayed_jobs_on_singleton_running",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
