# frozen_string_literal: true

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

module DataFixup::RunUpdateCourseScoreStatistic
  def self.run(start_at, end_at)
    # The migration will have us at most a range of 100,000 items,
    # we'll break it down to a thousand at a time here.
    Course.active.find_ids_in_ranges(start_at:, end_at:) do |batch_start, batch_end|
      courses_ids_to_recompute = Course.active.where(id: batch_start..batch_end).pluck(:id)
      courses_ids_to_recompute.each { |id| ScoreStatisticsGenerator.update_course_score_statistic(id) }
    end
  end
end
