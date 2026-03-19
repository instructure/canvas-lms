# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# This migration comes from switchman_inst_jobs (originally 20260120092005)
class AddMigrateFromJobsShard < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    add_reference :switchman_shards, :migrate_from_delayed_jobs_shard, foreign_key: { to_table: :switchman_shards }, index: true, if_not_exists: true
  end
end
