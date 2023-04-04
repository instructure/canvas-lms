# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module SimpleStats
  def variance(items, type = :population)
    return 0 if items.size < 2

    divisor = (type == :population) ? items.length : items.length - 1
    mean = items.sum / items.length.to_f
    sum = items.sum { |item| (item - mean)**2 }
    (sum / divisor).to_f
  end
  module_function :variance
end
