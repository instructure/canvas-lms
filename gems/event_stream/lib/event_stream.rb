# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "active_support"
require "active_record"
require "bookmarked_collection"
require "canvas_cassandra"
require "inst_statsd"

module EventStream
  require "event_stream/attr_config"
  require "event_stream/backend"
  require "event_stream/record"
  require "event_stream/failure"
  require "event_stream/logger"
  require "event_stream/stream"
  require "event_stream/index"

  def self.current_shard
    @current_shard_lookup&.call
  end

  def self.current_shard_lookup=(callable)
    @current_shard_lookup = callable
  end

  def self.get_index_ids(index, rows)
    @get_index_ids_lookup ||= ->(index2, rows2) { rows2.pluck(index2.id_column) }
    @get_index_ids_lookup.call(index, rows)
  end

  def self.get_index_ids_lookup=(callable)
    @get_index_ids_lookup = callable
  end
end
