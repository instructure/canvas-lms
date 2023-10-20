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

require "cassandra-cql"
require "benchmark"

module CanvasCassandra
  require "canvas_cassandra/database"
  require "canvas_cassandra/database_builder"

  class UnconfiguredError < StandardError; end

  mattr_accessor :logger
  mattr_writer :settings_store

  def self.consistency_level(name)
    CassandraCQL::Thrift::ConsistencyLevel.const_get(name.to_s.upcase)
  end

  # Expected interface for this object is:
  #   object.get(setting_name, 'default_value')
  # ^ returning a string
  # In this instance, it's expected that canvas is going to inject
  # the Setting class, but we want to break depednencies that directly
  # point to canvas.
  def self.settings_store(safe_invoke = false)
    return @@settings_store if @@settings_store
    return nil if safe_invoke

    raise UnconfiguredError, "an object with an interface for loading settings must be specified as 'settings_store'"
  end
end
