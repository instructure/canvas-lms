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
class LocalCache
  # Useful for things that can be shared by all processes on a box, but which
  # should not be stored on the distributed redis cache.  Vaulted credentials
  # are a good example.
  class << self
    delegate :clear, :delete, :delete_matched, :fetch, :fetch_without_expiration, :read, :write, :write_multi, to: :cache
    delegate :lock, :unlock, to: :cache

    def cache
      unless defined?(@local_cache)
        lc_config = ConfigFile.load("local_cache")
        @local_cache = if lc_config && lc_config[:store] == "redis"
                         Canvas::Cache::LocalRedisCache.new(lc_config)
                       else
                         Canvas::Cache::FallbackMemoryCache.new
                       end
      end
      @local_cache
    end

    def reset
      remove_instance_variable(:@local_cache) if instance_variable_defined?(:@local_cache)
    end
  end

  Canvas::Reloader.on_reload { reset }
end
