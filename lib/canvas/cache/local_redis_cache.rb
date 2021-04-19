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
module Canvas
  module Cache
    class LocalRedisCache < ActiveSupport::Cache::RedisCacheStore
      include ActiveSupport::Cache::SafeRedisRaceCondition
      include FallbackExpirationCache

      def initialize(local_cache_conf)
        redis = ::Redis.new(
          url: local_cache_conf[:redis_url],
          host: local_cache_conf[:redis_host],
          port: local_cache_conf[:redis_port],
          db: local_cache_conf[:redis_db]
        )
        @debounced_clear = ::Redis::Scripting::Script.new(File.expand_path("../debounced_clear.lua", __FILE__))
        super(redis: redis)
      end

      # canvas redis is patched to disallow "flush" operations,
      # but for a local-only cache should be safe.
      # Worth considering race conditions though.  Make sure
      # other operations that depend on redis (like dynamic_settings)
      # can tolerate a clear happening in between any 2 non-pipelined
      # commands
      def clear(force: false)
        if force
          GuardRail.activate(:deploy){ super }
        else
          # this makes sure only 1 process on a sighup'd box
          # will clear the cache, the others will find that the
          # debounce key is set and will do nothing
          @debounced_clear.run(redis, ["flush_debounce"], [30])
        end
      end

      # canvas redis is patched to disallow "scan" operations,
      # but clearing the whole thing does technically remove any
      # keys matching this pattern
      def delete_matched(pattern)
        clear
      end

      def write_set(hash, ttl: nil)
        opts = {expires_in: ttl}
        ms = 1000 * Benchmark.realtime do
          redis.pipelined do # send more commands before awaiting answer
            redis.multi do # make everything atomic in here
              hash.each do |k, v|
                write(k, v, opts)
              end
            end
          end
        end
        Rails.logger.debug("  #{"LOCAL REDIS (%.2fms)" % [ms]}  write_set {#{hash.keys.join(',')}}")
      end
    end
  end
end