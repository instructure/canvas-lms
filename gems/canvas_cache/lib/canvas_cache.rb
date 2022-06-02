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
module CanvasCache
  require "canvas_cache/redis"
  require "canvas_cache/hash_ring"
  require "canvas_cache/memory_settings"

  class UnconfiguredError < StandardError; end

  # TODO: Maybe at one point Setting will be
  # a gem on it's own or some other dependable module.
  # For the moment, this is a convenient way to inject
  # this base class without needing to depend on it directly.
  # This is safe to change after initialization, since none of the
  # returned settings are persistently cached in memory
  mattr_writer :settings_store, default: MemorySettings.new

  # this is expected to be a lambda which can be invoked
  # and passed an exception object if the caching library
  # catches it but decides not to deal with it
  mattr_writer :on_captured_error

  # Expected interface for this object is:
  #   object.get(setting_name, 'default_value') # [ returning a string ]
  #
  #   object.skip_cache do  # [ returning an uncached read of the string value ]
  #     object.get(setting_name, 'default_value')
  #   end
  #
  # In this instance, it's expected that canvas is going to inject
  # the Setting class, but we want to break depednencies that directly
  # point to canvas.
  def self.settings_store(safe_invoke = false)
    return @@settings_store if @@settings_store
    return nil if safe_invoke

    raise UnconfiguredError, "an object with an interface for loading settings must be specified as 'settings_store'"
  end

  # It would be great to pull out Canvas::Errors as a gem, and we should do so.
  # The problem is it has a dependency on RequestContextGenerator, which
  # has a dependency on Canvas::Security, which has a dependency on
  # our caching, and so we have to break the chain somewhere.  We're starting
  # with the caching.  TODO: Once canvas errors is out on it's own we can let
  # CanvasCache take a dependency on it directly and forego this touchpoint.
  def self.invoke_on_captured_error(exception)
    return if @@on_captured_error.nil?

    @@on_captured_error.call(exception)
  end
end
