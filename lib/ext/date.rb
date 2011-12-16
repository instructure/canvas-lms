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
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module ActiveSupport
  module CoreExtensions
    module Date
      module Conversions
        # Returns midnight on this date in the specified time zone (defaulting to
        # Time.zone). Use this rather than Date#to_time, which returns a Time object at
        # midnight in the system time zone, which we never care about.
        def in_time_zone(zone=::Time.zone)
          # would do zone = Time.get_zone(zone), but that's a private method,
          # and I'm a good boy
          ::Time.use_zone(zone) do
            ::Time.zone.local(self.year, self.month, self.day)
          end
        end
      end
    end
  end
end
