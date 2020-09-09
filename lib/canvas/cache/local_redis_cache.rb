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
      include FallbackExpirationCache

      def initialize(local_cache_conf)
        redis = ::Redis.new(host: local_cache_conf[:redis_host], port: local_cache_conf[:redis_port], db: local_cache_conf[:redis_db])
        super(redis: redis)
      end

      # canvas redis is patched to disallow "flush" operations,
      # but for a local-only cache should be safe.
      def clear
        Shackles.activate(:deploy){ super }
      end

      # canvas redis is patched to disallow "scan" operations,
      # but clearing the whole thing does technically remove any
      # keys matching this pattern
      def delete_matched(pattern)
        clear
      end
    end
  end
end