#
# Copyright (C) 2018 - present Instructure, Inc.
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

class UpdateAnonymousGradingSettings < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def self.up
    # Update assignments for courses and accounts with the old flag
    # explicitly enabled
    Course.find_ids_in_ranges(batch_size: 10_000) do |start_at, end_at|
      DataFixup::UpdateAnonymousGradingSettings.send_later_if_production_enqueue_args(
        :run_for_courses_in_range,
        {
          priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::UpdateAnonymousGradingSettings", Shard.current.database_server.id]
        },
        start_at,
        end_at
      )
    end

    Account.find_ids_in_ranges(batch_size: 10_000) do |start_at, end_at|
      DataFixup::UpdateAnonymousGradingSettings.send_later_if_production_enqueue_args(
        :run_for_accounts_in_range,
        {
          priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::UpdateAnonymousGradingSettings", Shard.current.database_server.id]
        },
        start_at,
        end_at
      )
    end

    # Get rid of the old flag on accounts where it was merely allowed
    DataFixup::UpdateAnonymousGradingSettings.send_later_if_production_enqueue_args(
      :destroy_allowed_and_off_flags,
      {
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::UpdateAnonymousGradingSettings", Shard.current.database_server.id]
      }
    )
  end
end
