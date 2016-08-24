module Canvas
  class RedisWrapper < SimpleDelegator
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
      options = keys.extract_options!
      super(*keys, options.merge(raw: true))
    end
  end
end
