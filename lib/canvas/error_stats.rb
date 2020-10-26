# frozen_string_literal: true

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
    def self.capture(exception, data, level=:error)
      category = exception
      unless exception.is_a?(String) || exception.is_a?(Symbol)
        category = exception.class.name
      end
      # careful!  adding tags is useful for finding things,
      # but every unique combination of tags gets treated
      # as a custom metric for billing purposes.  Only
      # add high value and low-ish cardinality tags.
      tags = data.fetch(:tags, {}).fetch(:for_stats, {})
      tags[:category] = category.to_s
      InstStatsd::Statsd.increment("errors.#{level}", tags: tags)
    end
  end
end
