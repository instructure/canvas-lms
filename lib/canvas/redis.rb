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
    reply = yield
    raise reply if reply.is_a?(Exception)
    reply
  rescue ::Redis::BaseConnectionError, SystemCallError, ::Redis::CommandError => e
    # We want to rescue errors such as "max number of clients reached", but not
    # actual logic errors such as trying to evalsha a script that doesn't
    # exist.
    # These are both CommandErrors, so we can only differentiate based on the
    # exception message.
    if e.is_a?(::Redis::CommandError) && e.message !~ /\bmax number of clients reached\b/
      raise
    end

    CanvasStatsd::Statsd.increment("redis.errors.all")
    CanvasStatsd::Statsd.increment("redis.errors.#{CanvasStatsd::Statsd.escape(redis_name)}")
    Rails.logger.error "Failure handling redis command on #{redis_name}: #{e.inspect}"

    if self.ignore_redis_failures?
      Canvas::Errors.capture(e, type: :redis)
      last_redis_failure[redis_name] = Time.zone.now
      failure_retval
    else
      raise
    end
  end

  class UnsupportedRedisMethod < RuntimeError
  end

  module Client
    def process(commands, *a, &b)
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
                    end

      Canvas::Redis.handle_redis_failure(failure_val, self.location) do
        super
      end
    end

    def write(command)
      if UNSUPPORTED_METHODS.include?(command.first.to_s)
        raise(UnsupportedRedisMethod, "Redis method `#{command.first}` is not supported by Twemproxy, and so shouldn't be used in Canvas")
      end
      if ALLOWED_UNSUPPORTED.include?(command.first.to_s) && Shackles.environment != :deploy
        raise(UnsupportedRedisMethod, "Redis method `#{command.first}` is potentially dangerous, and should only be called from console, and only if you fully understand the consequences. If you're sure, retry after running Shackles.activate!(:deploy)")
      end
      super
    end

    UNSUPPORTED_METHODS = %w[
      migrate
      move
      object
      randomkey
      rename
      renamenx
      scan
      bitop
      msetnx
      blpop
      brpop
      brpoplpush
      psubscribe
      publish
      punsubscribe
      subscribe
      unsubscribe
      discard
      exec
      multi
      unwatch
      watch
      script
      echo
      ping
    ].freeze

    # There are some methods that are not supported by twemproxy, but which we
    # don't block, because they are viewed as maintenance-type commands that
    # wouldn't be run as part of normal code, but could be useful to run
    # one-off in script/console if you aren't using twemproxy, or in specs:
    #
    # Note: I removed "auth" from this list since we are using Heroku redis addon which requires
    # authentication. This may not be the correct solution though. E.g. maybe passing a 'redis_auth'
    # config key or explicitly calling Redis::execute_command('AUTH', 'mypasswd'). Since we don't
    # have Twemproxy setup between us and the redis server, this is prob safe though.
    ALLOWED_UNSUPPORTED = %w[
      keys
      quit
      flushall
      flushdb
      info
      bgrewriteaof
      bgsave
      client
      config
      dbsize
      debug
      lastsave
      monitor
      save
      shutdown
      slaveof
      slowlog
      sync
      time
    ].freeze
  end

  def self.patch
    Redis::Client.prepend(Client)
  end
end
