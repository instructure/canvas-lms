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
      cause_category = nil
      unless exception.is_a?(String) || exception.is_a?(Symbol)
        category = exception.class.name
        if exception.respond_to?(:cause) && exception.cause.present?
          cause_category = exception.cause.class.name
        end
      end
      # careful!  adding tags is useful for finding things,
      # but every unique combination of tags gets treated
      # as a custom metric for billing purposes.  Only
      # add high value and low-ish cardinality tags.
      all_tags = data.fetch(:tags, {})
      stat_tags = all_tags.fetch(:for_stats, {})
      # convenience for propogating the "type" parameter
      # passed in Canvas::Errors.capture_exception,
      # which is usually a subsystem label
      stat_tags[:type] = all_tags[:type]
      stat_tags[:category] = category.to_s
      InstStatsd::Statsd.increment("errors.#{level}", tags: stat_tags)
      if cause_category.present?
        # if there's an inner exception, let's stat that one too.
        cause_tags = stat_tags.merge({category: cause_category.to_s})
        InstStatsd::Statsd.increment("errors.#{level}", tags: cause_tags)
      end
    end
  end
end
