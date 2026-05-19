# frozen_string_literal: true

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
#

class Loaders::CurrentGradingPeriodLoader < GraphQL::Batch::Loader
  def perform(courses)
    ActiveRecord::Associations.preload(courses, grading_period_groups: :active_grading_periods)
    ActiveRecord::Associations.preload(courses, enrollment_term: { grading_period_group: :active_grading_periods })

    courses.each do |course|
      grading_periods = course.grading_period_groups.flat_map(&:active_grading_periods)
      if grading_periods.empty? && course.enrollment_term&.grading_period_group
        grading_periods = course.enrollment_term.grading_period_group.active_grading_periods
      end
      current_grading_period = grading_periods.find(&:current?)

      fulfill course, [current_grading_period, grading_periods.any?]
    end
  end

  # this makes sure we only do the work once (even for different instances of
  # the same course)
  #
  # TODO: maybe i should be using the enrollment_term instead and then i think
  # all courses in that term work for free
  def cache_key(course)
    course.global_id
  end
end
