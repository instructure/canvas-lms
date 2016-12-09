#
# Copyright (C) 2016 Instructure, Inc.
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
module Canvas
  class FailurePercentCounter
    def initialize(redis, redis_key, period = 60.seconds, min_samples = 100)
      @redis = redis
      @count_key = "#{redis_key}:total_count"
      @fail_key = "#{redis_key}:fail"
      @period = period
      @min_samples = min_samples
    end

    def increment_count
      increment(@count_key)
    end

    def increment_failure
      increment(@fail_key)
    end

    def failure_rate
      now = Time.now.utc.to_i
      # ideally we'd want to do all the redis calls in a redis.multi
      # so they are atomic, but canvas uses an abstraction layer that
      # doesn't expose that
      count = cleanup_and_get(@count_key, now)
      failure = cleanup_and_get(@fail_key, now)

      # If our sample size is too small, let's claim total success
      return 0.0 if count < @min_samples
      failure.fdiv(count)
    end

    private
    def increment(key)
      now = Time.now.utc.to_i
      # ideally we'd want to do all the redis calls in a redis.multi
      # so they are atomic, but canvas uses an abstraction layer that
      # doesn't expose that
      @redis.zadd(key, now, SecureRandom.uuid)
      @redis.expire(key, @period.ceil)
      cleanup_and_get(key, now)
    end

    def cleanup_and_get(key, now)
      cleanup_time = now - @period
      @redis.zremrangebyscore(key, 0, cleanup_time)
      @redis.zcount(key, cleanup_time, now)
    end
  end
end
