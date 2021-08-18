# frozen_string_literal: true

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
module DynamicSettings
  class CircuitBreaker
    def initialize(reset_interval = 1.minute)
      @reset_interval = reset_interval
    end

    def tripped?
      return false unless @reset_interval

      @tripped_at && (Time.now.utc - @tripped_at) < @reset_interval
    end

    def trip
      @tripped_at = Time.now.utc
    end
  end
end
