# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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

module Utils
  class TimePresenter
    attr_reader :time, :zone
    def initialize(time, zone=nil)
      zone ||= ::Time.zone
      @time = time.in_time_zone(zone) rescue time
      @zone = zone
    end

    def as_string(options={})
      return nil unless time
      range_time = get_range_time(options[:display_as_range])
      if is_range?(range_time)
        other = TimePresenter.new(range_time, zone)
        I18n.t('time.ranges.times', "%{start_time} to %{end_time}",
               start_time: formatted_result, end_time: other.as_string)
      else
        formatted_result
      end
    end

    private
    def formatted_result
      I18n.l(time, format: format)
    end

    def get_range_time(raw)
      raw.in_time_zone(zone) rescue raw
    end

    def is_range?(range_time)
      range_time && range_time != time
    end

    def format
      time.min == 0 ? :tiny_on_the_hour : :tiny
    end
  end
end
