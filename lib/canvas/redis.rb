# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  # TODO: This implementation is being moved to the gem CanvasCache
  # but this shim is helping us not break in the meantime.
  # once that has replaced all callsites,
  # we won't need this shim anymore, and can drop this file entirely.
  Redis = CanvasCache::Redis
end

# TODO: the connection management being delegated here
# isn't necessarily part of the canvas_cache gem.
# Once callsites have been updated to use the RedisConnections module
# instead, we can drop this module re-openning.
class << Canvas::Redis
  # technically this is just disconnect_redis, because new connections are created lazily,
  # but we didn't want to rename it when there are several uses of it
  def reconnect_redis
    Canvas::RedisConnections.disconnect!
  end

  def clear_idle_connections
    Canvas::RedisConnections.clear_idle!
  end
end
