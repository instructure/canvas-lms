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
      last_redis_failure[redis_name] = Time.now
      failure_retval
    else
      raise
    end
  end

  class UnsupportedRedisMethod < RuntimeError
  end

  module Client
    def process(commands, *a, &b)
      # These instance vars are used by the added #log_request_response method.
      @processing_requests = commands.map(&:dup)
      @process_start = Time.now

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

    NON_KEY_COMMANDS = %i[eval evalsha].freeze

    def read
      response = super
      # Each #read grabs the response to one command send to #process, so we
      # pop off the next queued request and send that to the logger. The redis
      # client works this way because #process may be called with many commands
      # at once, if using #pipeline.
      @processing_requests ||= []
      @process_start ||= Time.now
      log_request_response(@processing_requests.shift, response, @process_start)
      response
    end

    def log_request_response(request, response, start_time)
      return if request.nil? # redis client does internal keepalives and connection commands

      command = request.shift
      message = {
        message: "redis_request".freeze,
        command: command,
        # request_size is the sum of all the string parameters send with the command.
        request_size: request.sum { |c| c.to_s.size },
        request_time_ms: (Time.now - start_time) * 1000,
        host: location,
      }
      unless NON_KEY_COMMANDS.include?(command)
        message[:key] = request.first
      end
      if defined?(Marginalia)
        message[:controller] = Marginalia::Comment.controller
        message[:action] = Marginalia::Comment.action
        message[:job_tag] = Marginalia::Comment.job_tag
      end
      if command == :set && Thread.current[:last_cache_generate]
        # :last_cache_generate comes from the instrumentation added in
        # config/initializeers/cache_store_instrumentation.rb
        # This is necessary because the Rails caching layer doesn't pass this
        # information down to the Redis client -- we could try to infer it by
        # looking for reads followed by writes to the same key, but this would be
        # error prone, especially since further cache reads can happen inside the
        # generation block.
        message[:generate_time_ms] = Thread.current[:last_cache_generate] * 1000
        Thread.current[:last_cache_generate] = nil
      end
      if response.is_a?(Exception)
        message[:error] = response.to_s
        message[:response_size] = 0
      else
        message[:response_size] = response.try(:size) || 0
      end

      logline = JSON.generate(message.compact)
      Rails.logger.debug(logline) if Rails.logger
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
    ALLOWED_UNSUPPORTED = %w[
      keys
      auth
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
