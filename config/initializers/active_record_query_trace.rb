# frozen_string_literal: true

#
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

module ARQueryTraceInitializer
  VALID_QUERY_TYPES = %i[all read write].freeze
  VALID_LEVELS = %i[app rails full].freeze

  def self.configure!
    return if Rails.env.production?
    return unless Canvas::Plugin.value_to_boolean(ENV["AR_QUERY_TRACE"])

    require "active_record_query_trace"

    lines_in_trace = ENV["AR_QUERY_TRACE_LINES"].to_i
    query_types = ENV["AR_QUERY_TRACE_TYPE"]&.to_sym
    level = ENV["AR_QUERY_TRACE_LEVEL"]&.to_sym

    ActiveRecordQueryTrace.enabled = true
    ActiveRecordQueryTrace.lines = lines_in_trace.zero? ? 10 : lines_in_trace
    ActiveRecordQueryTrace.query_type = VALID_QUERY_TYPES.include?(query_types) ? query_types : :all
    ActiveRecordQueryTrace.level = level if VALID_LEVELS.include?(level)
  end
end

ARQueryTraceInitializer.configure!
