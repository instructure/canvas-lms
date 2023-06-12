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
module CoursePacesDateHelpers
  class << self
    def add_days(start_date, duration, exclude_weekends, blackout_dates = [])
      return nil unless start_date && duration

      BusinessTime::Config.with(business_time_config(exclude_weekends, blackout_dates)) do
        duration.business_days.after(start_date)
      end
    end

    def previous_enabled_day(start_date, exclude_weekends, blackout_dates)
      BusinessTime::Config.with(business_time_config(exclude_weekends, blackout_dates)) do
        Time.previous_business_day(start_date)
      end
    end

    def first_enabled_day(start_date, exclude_weekends, blackout_dates)
      BusinessTime::Config.with(business_time_config(exclude_weekends, blackout_dates)) do
        Time.first_business_day(start_date)
      end
    end

    def day_is_enabled?(date, exclude_weekends, blackout_dates)
      BusinessTime::Config.with(business_time_config(exclude_weekends, blackout_dates)) do
        date.workday?
      end
    end

    def days_between(start_date, end_date, exclude_weekends, inclusive_end: true, blackout_dates: [])
      return nil if end_date.nil?

      BusinessTime::Config.with(business_time_config(exclude_weekends, blackout_dates)) do
        start_date.to_date.business_days_until(end_date, inclusive_end)
      end
    end

    private

    def business_time_config(exclude_weekends, blackout_dates)
      work_week = exclude_weekends ? %i[mon tue wed thu fri] : %i[sun mon tue wed thu fri sat]
      holidays =
        blackout_dates.map do |blackout_date|
          if blackout_date.is_a?(CalendarEvent)
            (blackout_date.start_at.to_date..blackout_date.end_at.to_date).to_a
          else
            (blackout_date.start_date..blackout_date.end_date).to_a
          end
        end.flatten

      {
        work_week:,
        holidays:,
      }
    end
  end
end
