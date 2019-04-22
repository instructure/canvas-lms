#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas
  # Simple class for shipping errors to statsd based on the format
  # propogated from callbacks on Canvas::Errors
  class ErrorStats
    def self.capture(exception, _data)
      category = exception
      unless exception.is_a?(String) || exception.is_a?(Symbol)
        category = exception.class.name
      end
      InstStatsd::Statsd.increment("errors.all")
      InstStatsd::Statsd.increment("errors.#{category}")
    end
  end
end
