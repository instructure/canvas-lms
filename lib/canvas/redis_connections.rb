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

module Canvas
  ##
  # RedisConnections is glue between the canvas
  # app and the canvas_cache gem.
  # Things like idle connection clearing
  # require knowing the topology of our redis
  # clusters and how they're cached in Switchman,
  # information that's not important to push down
  # into canvas_cache.
  class RedisConnections
    ##
    # Drops every open connection, including both MultiCache (local)
    # and connections to remote redis nodes
    def self.disconnect!
      if Rails.cache &&
         defined?(ActiveSupport::Cache::RedisCacheStore) &&
         Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
        redis = Rails.cache.redis
        if redis.respond_to?(:nodes)
          redis.nodes.each(&:close)
        else
          redis.close
        end
      end

      if MultiCache.cache.is_a?(ActiveSupport::Cache::HaStore)
        redis = MultiCache.cache.redis
        if redis.respond_to?(:nodes)
          redis.nodes.each(&:close)
        else
          redis.close
        end
      end

      ::CanvasCache::Redis.disconnect!
    end

    ##
    # call somewhat frequently (e.g. every minute or so)
    # to make sure we aren't holding open connections we aren't
    # using.
    def self.clear_idle!
      clear_frequency = 1.minute.to_i
      clear_timeout = 1.minute.to_i
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @last_clear_time ||= now
      if (now - @last_clear_time) > clear_frequency
        @last_clear_time = now
        # gather all the redises we can find
        redises = Switchman.config[:cache_map].values
                           .filter_map { |cache| cache.try(:redis) }.uniq
                           .map { |redis| redis.try(:ring)&.nodes || [redis] }.inject([], &:concat).uniq
        redises.each { |r| r._client.disconnect_if_idle(@last_clear_time - clear_timeout) }
      end
    end
  end
end
