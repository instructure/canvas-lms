#
# Copyright (C) 2016 - present Instructure, Inc.
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

class RecomputeEnrollmentStates < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    # copy-pasted from build_enrollment_states
    # try to partition off ranges of ids in the table with at most 50,000 ids per partition
    ranges = []
    current_min = Enrollment.minimum(:id)
    return unless current_min

    range_size = 50_000

    while current_min
      current_max = current_min + range_size - 1

      next_min = Enrollment.where("id > ?", current_max).minimum(:id)
      if next_min
        ranges << [current_min, current_max]
      elsif !next_min && ranges.any?
        ranges << [current_min, nil]
      end
      current_min = next_min
    end

    unless ranges.any?
      ranges = [[nil, nil]]
    end

    ranges.each do |start_at, end_at|
      DataFixup::RecomputeEnrollmentStates.send_later_if_production_enqueue_args(:run,
        {:strand => "enrollment_state_recomputing_#{Shard.current.database_server.id}", :priority => Delayed::MAX_PRIORITY}, start_at, end_at)
    end
  end

  def down
  end
end
