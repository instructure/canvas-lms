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
  VALID_QUERY_TYPES = %i(all read write).freeze

  def self.configure!
    return unless Rails.env.development?
    return if ENV['AR_QUERY_TRACE'].blank?

    lines_in_trace = ENV['AR_QUERY_TRACE_LINES'].to_i
    query_types = ENV['AR_QUERY_TRACE_TYPE']&.to_sym

    ActiveRecordQueryTrace.enabled = true
    ActiveRecordQueryTrace.lines = lines_in_trace.zero? ? 10 : lines_in_trace
    ActiveRecordQueryTrace.query_type = VALID_QUERY_TYPES.include?(query_types) ? query_types : :all
  end
end

ARQueryTraceInitializer.configure!
