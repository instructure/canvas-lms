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
#

require_relative "canvas_cache/redis_cache_store"
require_relative "canvas_cache/memory_settings"
require_relative "canvas_cache/hash_ring"
require_relative "canvas_cache/redis"
require_relative "redis_client/logging"
require_relative "redis_client/max_clients"
require_relative "redis_client/twemproxy"

module CanvasCache
  class UnconfiguredError < StandardError; end

  class << self
    # TODO: Maybe at one point Setting will be
    # a gem on it's own or some other dependable module.
    # For the moment, this is a convenient way to inject
    # this base class without needing to depend on it directly.
    # This is safe to change after initialization, since none of the
    # returned settings are persistently cached in memory
    attr_writer :settings_store

    # Expected interface for this object is:
    #   object.get(setting_name, 'default_value') # [ returning a string ]
    #
    # In this instance, it's expected that canvas is going to inject
    # the Setting class, but we want to break depednencies that directly
    # point to canvas.
    def settings_store
      return @settings_store if @settings_store

      raise UnconfiguredError, "an object with an interface for loading settings must be specified as 'settings_store'"
    end
  end

  @settings_store = MemorySettings.new
end
