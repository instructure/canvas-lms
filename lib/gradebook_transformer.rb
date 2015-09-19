#
# Copyright (C) 2015 Instructure, Inc.
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
#

module GradebookTransformer
  private
  def select_in_current_grading_periods(assignments, course)
    if course.feature_enabled?(:multiple_grading_periods)
      assignments, assignments_without_due_at = assignments.partition(&:due_at)
      current_periods = GradingPeriod.for(course).active.current

      current = assignments.select do |assignment|
        current_periods.any? { |p| p.in_date_range? assignment.due_at }
      end

      current + assignments_without_due_at
    else
      assignments
    end
  end
end
