#
# Copyright (C) 2017 - present Instructure, Inc.
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

class ValidateAssignmentOverrides < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def self.up
    Assignment.find_ids_in_ranges(:batch_size => 10_000) do |start_at, end_at|
      DataFixup::ValidateAssignmentOverrides.send_later_if_production_enqueue_args(:run, {
          priority: Delayed::LOW_PRIORITY,
          max_attempts: 1,
          n_strand: ["DataFixup::ValidateAssignmentOverrides", Shard.current.database_server.id]
        }, start_at, end_at
      )
    end
  end

  def self.down
  end
end
