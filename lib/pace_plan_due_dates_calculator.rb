# frozen_string_literal: true

#
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
#
class PacePlanDueDatesCalculator
  attr_reader :pace_plan

  def initialize(pace_plan)
    @pace_plan = pace_plan
  end

  def get_due_dates(items, enrollment = nil)
    due_dates = {}
    start_date = enrollment&.start_at&.to_date || pace_plan.start_date

    # We have to make sure we start counting from one day before the plan start, so that the first day is inclusive.
    # If the plan start date is enabled (i.e., not on a blackout date) we can just subtract one working day.
    # However, if the plan start date is on a blackout date this will cause issues, because the BusinessTime
    # `business_days.after` method will find the day before the first workday when you subtract, which means we'll
    # be one day off in our calculation. So if the day is disabled, we just find the first enabled day in the past,
    # and start from that.
    start_date = if PacePlansDateHelpers.day_is_enabled?(start_date, pace_plan.exclude_weekends,
                                                         blackout_dates)
                   PacePlansDateHelpers.add_days(start_date, -1, pace_plan.exclude_weekends, blackout_dates)
                 else
                   PacePlansDateHelpers.previously_enabled_day(start_date, pace_plan.exclude_weekends,
                                                               blackout_dates)
                 end

    items.each_with_index do |item, index|
      duration = index == 0 && item.duration == 0 ? 1 : item.duration

      due_date = PacePlansDateHelpers.add_days(
        start_date,
        duration,
        pace_plan.exclude_weekends,
        blackout_dates
      )
      due_dates[item.id] = due_date.to_date
      start_date = due_date # The next item's start date is this item's due date
    end

    due_dates
  end

  private

  def blackout_dates
    @blackout_dates ||= pace_plan.course.blackout_dates
  end
end
