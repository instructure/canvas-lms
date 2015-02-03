module Canvas
  class RedisWrapper < SimpleDelegator
    UNSUPPORTED_METHODS = %w[
      keys
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
    ]

    # There are some methods that are not supported by twemproxy, but which we
    # don't block, because they are viewed as maintenance-type commands that
    # wouldn't be run as part of normal code, but could be useful to run
    # one-off in script/console if you aren't using twemproxy, or in specs:
    ALLOWED_UNSUPPORTED = %w[
      auth
      quit
      select
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
    ]

    class UnsupportedRedisMethod < RuntimeError
    end

    UNSUPPORTED_METHODS.each do |method|
      define_method(method) { |*a|
        raise(UnsupportedRedisMethod, "Redis method `#{method}` is not supported by Twemproxy, and so shouldn't be used in Canvas")
      }
    end

    # We don't marshal for the data wrapper
    def set(key, value, options = nil)
      options ||= {}
      super(key, value, options.merge(raw: true))
    end

    def setnx(key, value, options = nil)
      options ||= {}
      super(key, value, options.merge(raw: true))
    end

    def setex(key, expiry, value, options = nil)
      options ||= {}
      super(key, expiry, value, options.merge(raw: true))
    end

    def get(key, options = nil)
      options ||= {}
      super(key, options.merge(raw: true))
    end

    def mget(*keys)
      options keys.extract_options!
      super(*keys, options.merge(raw: true))
    end
  end
end
