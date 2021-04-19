# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module CanvasSort
  class LastClass
    include Comparable

    def <=>(b)
      b.is_a?(LastClass) ? 0 : 1
    end

    # String#<=> checks if its arg is a string, and if it's not, calls to_str.
    # as long as to_str doesn't throw an error, then it calls arg <=> self,
    # ignoring the result of to_str. I figured to_str result of nil makes more
    # sense than returning a non-string from to_str
    def to_str
      nil
    end

    def to_datetime
      Date::Infinity.new
    end

    def inspect
      'CanvasSort::Last'
    end

    # when coercing, we're inverting the operation, so invert the result
    def coerce(something)
      [First, something]
    end
  end

  Last = LastClass.new
end
