module Canvas::Redis
  # try to grab a lock in Redis, returning false if the lock can't be held. If
  # the lock is grabbed and `ttl` is given, it'll be set to expire after `ttl`
  # seconds.
  def self.lock(key, ttl = nil)
    return true unless Canvas.redis_enabled?
    full_key = lock_key(key)
    if Canvas.redis.setnx(full_key, 1)
      Canvas.redis.expire(full_key, ttl.to_i) if ttl
      true
    else
      # key is already used
      false
    end
  end

  # unlock a previously grabbed Redis lock. This doesn't do anything to verify
  # that this process took the lock.
  def self.unlock(key)
    Canvas.redis.del(lock_key(key))
    true
  end

  def self.lock_key(key)
    "lock:#{key}"
  end

  # while we wait for this pull request
  # https://github.com/jodosha/redis-store/pull/83
  def self.patch

    ::ActiveSupport::Cache::RedisStore.class_eval do
      def write_with_econnrefused(key, value, options = nil)
        write_without_econnrefused(key, value, options)
      rescue Errno::ECONNREFUSED => e
        false
      end
      alias_method_chain :write, :econnrefused

      def read_with_econnrefused(key, options = nil)
        read_without_econnrefused(key, options)
      rescue Errno::ECONNREFUSED => e
        nil
      end
      alias_method_chain :read, :econnrefused

      def delete_with_econnrefused(key, options = nil)
        delete_without_econnrefused(key, options)
      rescue Errno::ECONNREFUSED => e
        false
      end
      alias_method_chain :delete, :econnrefused

      def exist_with_econnrefused?(key, options = nil)
        exist_without_econnrefused?(key, options = nil)
      rescue Errno::ECONNREFUSED => e
        false
      end
      alias_method_chain :exist?, :econnrefused

      def delete_matched_with_econnrefused(matcher, options = nil)
        delete_matched_without_econnrefused(matcher, options)
      rescue Errno::ECONNREFUSED => e
        false
      end
      alias_method_chain :delete_matched, :econnrefused
    end
  end
end
