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
  # NOTE: this isn't really doing any batch loading currently. it's just here
  # to avoid re-computing which grading period goes to the same course (like
  # when fetching grades for all students in a course)
  # (if someone wants to modify the grading period stuff for batching then
  # thank you)
  def perform(courses)
    courses.each { |course|
      grading_periods = GradingPeriod.for(course)
      current_grading_period = grading_periods.find(&:current?)

      fulfill course, [current_grading_period, grading_periods.any?]
    }
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
