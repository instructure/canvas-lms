# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require 'event_stream/backend/strategy'
require 'event_stream/backend/cassandra'
require 'event_stream/backend/active_record'

module EventStream
  module Backend
    def self.for_strategy(stream, strategy_name)
      const_get(strategy_name.to_s.classify, false).new(stream)
    rescue NameError
      raise "Unknown EventStream Strategy: #{strategy_name}"
    end
  end
end