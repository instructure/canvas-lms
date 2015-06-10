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
  class RelativeDate
    attr_reader :date, :zone

    def initialize(date, zone=nil)
      @date = date
      @zone = zone || Time.zone
    end

    def today?
      date == today
    end

    def tomorrow?
      date == today + 1
    end

    def yesterday?
      date == today - 1
    end

    def this_week?
      date < today + 1.week && date >= today
    end

    def this_year?
      date.year == today.year
    end

    private
    def today
      zone.today
    end
  end
end
