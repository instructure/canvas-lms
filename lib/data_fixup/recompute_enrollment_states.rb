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

module DataFixup
  module RecomputeEnrollmentStates
    def self.run(start_at, end_at)
      Enrollment.find_ids_in_ranges(:start_at => start_at, :end_at => end_at) do |min_id, max_id|
        enrollments = Enrollment.where(:id => min_id..max_id).to_a

        Canvas::Builders::EnrollmentDateBuilder.preload(enrollments, false)

        enrollments.each do |enrollment|
          state = enrollment.enrollment_state
          state.skip_touch_user = true

          state.state_is_current = false
          state.access_is_current = false
          state.ensure_current_state
        end

        user_ids_to_touch = enrollments.select{|e| e.enrollment_state.user_needs_touch}.map(&:user_id)
        if user_ids_to_touch.any?
          Shard.partition_by_shard(user_ids_to_touch) do |sliced_user_ids|
            User.where(:id => sliced_user_ids).touch_all
          end
        end
      end
    end
  end
end