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

  def self.ignore_redis_failures?
    Setting.get('ignore_redis_failures', 'true') == 'true'
  end

  def self.redis_failure?(redis_name)
    return false unless last_redis_failure[redis_name]
    # i feel this dangling rescue is justifiable, given the try-to-be-failsafe nature of this code
    return (Time.now - last_redis_failure[redis_name]) < (Setting.get('redis_failure_time', '300').to_i rescue 300)
  end

  def self.last_redis_failure
    @last_redis_failure ||= {}
  end

  def self.reset_redis_failure
    @last_redis_failure = {}
  end

  def self.handle_redis_failure(failure_retval, redis_name)
    return failure_retval if redis_failure?(redis_name)
    yield
  rescue Redis::BaseConnectionError => e
    CanvasStatsd::Statsd.increment("redis.errors.all")
    CanvasStatsd::Statsd.increment("redis.errors.#{CanvasStatsd::Statsd.escape(redis_name)}")
    Rails.logger.error "Failure handling redis command on #{redis_name}: #{e.inspect}"
    if self.ignore_redis_failures?
      ErrorReport.log_exception(:redis, e)
      last_redis_failure[redis_name] = Time.now
      failure_retval
    else
      raise
    end
  end

  def self.patch
    return if @redis_patched
    Redis::Client.class_eval do
      def process_with_conn_error(commands, *a, &b)
        # try to return the type of value the command would expect, for some
        # specific commands that we know can cause problems if we just return
        # nil
        #
        # this isn't fool-proof, and in some situations it would probably
        # actually be nicer to raise the exception and let the app handle it,
        # but it's what we're going with for now
        #
        # for instance, Rails.cache.delete_matched will error out if the 'keys' command returns nil instead of []
        last_command = commands.try(:last)
        failure_val = case (last_command.respond_to?(:first) ? last_command.first : last_command).to_s
          when 'keys', 'hmget'
            []
          when 'del'
            0
          else
            nil
        end

        Canvas::Redis.handle_redis_failure(failure_val, self.location) do
          process_without_conn_error(commands, *a, &b)
        end
      end
      alias_method_chain :process, :conn_error
    end
    @redis_patched = true
  end
end
