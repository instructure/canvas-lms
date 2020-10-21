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

module Canvas::Redis
  def self.clear_idle_connections
    # every 1 minute, clear connections that have been idle at least a minute
    clear_frequency = Setting.get("clear_idle_connections_frequency", 60).to_i
    clear_timeout = Setting.get("clear_idle_connections_timeout", 60).to_i
    @last_clear_time ||= Time.now.utc
    if (Time.now.utc - @last_clear_time > clear_frequency)
      @last_clear_time = Time.now.utc
      # gather all the redises we can find
      redises = Switchman.config[:cache_map].values.
        map { |cache| cache.try(:redis) }.compact.uniq.
        map { |redis| redis.try(:ring)&.nodes || [redis] }.inject([], &:concat).uniq
      redises.each { |r| r._client.disconnect_if_idle(@last_clear_time - clear_timeout) }
    end
  end

  # try to grab a lock in Redis, returning false if the lock can't be held. If
  # the lock is grabbed and `ttl` is given, it'll be set to expire after `ttl`
  # seconds.
  def self.lock(key, ttl = nil)
    return true unless Canvas.redis_enabled?
    full_key = lock_key(key)
    if Canvas.redis.setnx(full_key, 1)
      Canvas.redis.expire(full_key, ttl.to_i) if ttl
      true else
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

  COMPACT_LINE = "Redis (%{request_time_ms}ms) %{command} %{key} [%{host}]".freeze
  def self.log_style
    # supported: 'off', 'compact', 'json'
    @log_style ||= ConfigFile.load('redis')&.[]('log_style') || 'compact'
  end

  def self.redis_failure?(redis_name)
    return false unless last_redis_failure[redis_name]
    # i feel this dangling rescue is justifiable, given the try-to-be-failsafe nature of this code
    if redis_name =~ /localhost/
      # talking to local redis should not short ciruit as long
      return (Time.now - last_redis_failure[redis_name]) < (Setting.get('redis_local_failure_time', '2').to_i rescue 2)
    end
    return (Time.now - last_redis_failure[redis_name]) < (Setting.get('redis_failure_time', '300').to_i rescue 300)
  end

  def self.last_redis_failure
    @last_redis_failure ||= {}
  end

  def self.reset_redis_failure
    @last_redis_failure = {}
  end

  def self.handle_redis_failure(failure_retval, redis_name)
    Setting.skip_cache do
      if redis_failure?(redis_name)
        Rails.logger.warn("  [REDIS] Short circuiting due to recent redis failure (#{redis_name})")
        return failure_retval
      end
    end
    reply = yield
    raise reply if reply.is_a?(Exception)
    reply
  rescue ::Redis::BaseConnectionError, SystemCallError, ::Redis::CommandError => e
    # spring calls its after_fork hooks _after_ establishing a new db connection
    # after forking. so we don't get a chance to close the connection. just ignore
    # the error (but lets use logging to make sure we know if it happens)
    Rails.logger.error("  [REDIS] Query failure #{e.inspect} (#{redis_name})")
    return failure_retval if e.is_a?(::Redis::InheritedError) && defined?(Spring)

    # We want to rescue errors such as "max number of clients reached", but not
    # actual logic errors such as trying to evalsha a script that doesn't
    # exist.
    # These are both CommandErrors, so we can only differentiate based on the
    # exception message.
    if e.is_a?(::Redis::CommandError) && e.message !~ /\bmax number of clients reached\b/
      raise
    end

    InstStatsd::Statsd.increment("redis.errors.all")
    InstStatsd::Statsd.increment("redis.errors.#{InstStatsd::Statsd.escape(redis_name)}",
                                 short_stat: 'redis.errors',
                                 tags: {redis_name: InstStatsd::Statsd.escape(redis_name)})
    Rails.logger.error "Failure handling redis command on #{redis_name}: #{e.inspect}"

    Setting.skip_cache do
      if self.ignore_redis_failures?
        Canvas::Errors.capture(e, type: :redis)
        last_redis_failure[redis_name] = Time.now
        failure_retval
      else
        raise
      end
    end
  end

  class UnsupportedRedisMethod < RuntimeError
  end

  BoolifySet =
    lambda { |value|
      if value && "OK" == value
        true
      elsif value && :failure == value
        nil
      else
        false
      end
    }

  module Client
    def disconnect_if_idle(since_when)
      disconnect if !@process_start || @process_start < since_when
    end

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
      last_command_args = Array.wrap(last_command)
      last_command = (last_command.respond_to?(:first) ? last_command.first : last_command).to_s
      failure_val = case last_command
                    when 'keys', 'hmget', 'mget'
                      []
                    when 'scan'
                      ["0", []]
                    when 'del'
                      0
                    end
      if last_command == 'set' && (last_command_args.include?('XX') || last_command_args.include?('NX'))
        failure_val = :failure
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

    SET_COMMANDS = %i{set setex}.freeze
    def log_request_response(request, response, start_time)
      return if request.nil? # redis client does internal keepalives and connection commands
      return if Canvas::Redis.log_style == 'off'
      return unless Rails.logger

      command = request.shift
      message = {
        message: "redis_request".freeze,
        command: command,
        # request_size is the sum of all the string parameters send with the command.
        request_size: request.sum { |c| c.to_s.size },
        request_time_ms: ((Time.now - start_time) * 1000).round(3),
        host: location,
      }
      unless NON_KEY_COMMANDS.include?(command)
        if command == :mset
          # This is an array with a single element: an array alternating key/values
          message[:key] = request.first { |v| v.first }.select.with_index { |_,i| (i) % 2 == 0 }
        elsif command == :mget
          message[:key] = request
        else
          message[:key] = request.first
        end
      end
      if defined?(Marginalia)
        message[:controller] = Marginalia::Comment.controller
        message[:action] = Marginalia::Comment.action
        message[:job_tag] = Marginalia::Comment.job_tag
      end
      if SET_COMMANDS.include?(command) && Thread.current[:last_cache_generate]
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

      logline = format_log_message(message)
      Rails.logger.debug(logline)
    end

    def format_log_message(message)
      if Canvas::Redis.log_style == 'json'
        JSON.generate(message.compact)
      else
        message[:key] ||= "-"
        Canvas::Redis::COMPACT_LINE % message
      end
    end

    def write(command)
      if UNSUPPORTED_METHODS.include?(command.first.to_s)
        raise(UnsupportedRedisMethod, "Redis method `#{command.first}` is not supported by Twemproxy, and so shouldn't be used in Canvas")
      end
      if ALLOWED_UNSUPPORTED.include?(command.first.to_s) && GuardRail.environment != :deploy
        raise(UnsupportedRedisMethod, "Redis method `#{command.first}` is potentially dangerous, and should only be called from console, and only if you fully understand the consequences. If you're sure, retry after running GuardRail.activate!(:deploy)")
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

  module Distributed
    def initialize(addresses, options = { })
      options[:ring] ||= Canvas::HashRing.new([], options[:replicas], options[:digest])
      super
    end
  end

  def self.patch
    Bundler.require 'redis'
    require 'redis/distributed'

    Redis::Client.prepend(Client)
    Redis::Distributed.prepend(Distributed)
    Redis.send(:remove_const, :BoolifySet)
    Redis.const_set(:BoolifySet, BoolifySet)
  end
end
