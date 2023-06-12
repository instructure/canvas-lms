# frozen_string_literal: true

# Copyright (C) 2014 - present Instructure, Inc.
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

module Utils
  class DatetimeRangePresenter
    attr_reader :start, :zone, :with_weekday

    def initialize(datetime, end_datetime = nil, datetime_type = :event, zone = nil, with_weekday: false)
      zone ||= ::Time.zone
      @start = datetime.in_time_zone(zone) rescue datetime
      @_finish = end_datetime.in_time_zone(zone) rescue end_datetime
      @_datetime_type = datetime_type
      @zone = zone
      @with_weekday = with_weekday
    end

    def as_string(options = {})
      return nil unless start

      shorten_midnight = options.fetch(:shorten_midnight, false)
      if is_not_range?
        if shorten_midnight && should_display_as_date?
          start_date_string
        else
          datetime_component(start_date_string, start)
        end
      else
        present_range
      end
    end

    private

    def present_range
      if start.to_date == finish.to_date
        I18n.t("time.ranges.same_day",
               "%{date} from %{start_time} to %{end_time}",
               date: start_date_string,
               start_time: start_as_time,
               end_time: finish_as_time)
      else
        start_string = datetime_component(start_date_string, start)
        end_string = datetime_component(end_date_string, finish)
        I18n.t("time.ranges.different_days",
               "%{start_date_and_time} to %{end_date_and_time}",
               start_date_and_time: start_string,
               end_date_and_time: end_string)
      end
    end

    def should_display_as_date?
      (datetime_type == :due_date && start.hour == 23 && start.min == 59) ||
        (datetime_type == :event && start.hour == 0 && start.min == 0)
    end

    def is_not_range?
      !finish || finish == start
    end

    def start_as_time
      present_time(start)
    end

    def finish_as_time
      present_time(finish)
    end

    def datetime_component(date_string, time)
      time_string = present_time(time)
      if datetime_type == :due_date
        I18n.t("time.due_date", "%{date} by %{time}", date: date_string, time: time_string)
      else
        I18n.t("time.event", "%{date} at %{time}", date: date_string, time: time_string)
      end
    end

    def start_date_string
      present_date(start)
    end

    def end_date_string
      present_date(finish)
    end

    def present_time(time)
      TimePresenter.new(time, zone).as_string
    end

    def present_date(date)
      Utils::DatePresenter.new(date.to_date, zone, with_weekday:).as_string(date_style)
    end

    def finish
      return nil if datetime_type == :due_date || !valid_raw_type?

      @_finish
    end

    def date_style
      case datetime_type
      when :verbose
        :long
      when :weekday_only
        :weekday
      else
        :no_words
      end
    end

    def datetime_type
      return @_datetime_type if valid_raw_type?

      :event
    end

    def valid_raw_type?
      @_datetime_type.is_a?(Symbol)
    end
  end
end
