module Canvas
  # defines the behavior when a protected attribute is assigned to in mass
  # assignment. The default, and Rails' normal behavior, is to just :log. Set
  # this to :raise to raise an exception.
  mattr_accessor :protected_attribute_error

  # defines the behavior around casting arguments passed into dynamic finders.
  # Arguments are coerced to the appropriate type (if the column exists), so
  # things like find_by_id('123') become find_by_id(123). The default (:log)
  # logs a warning if the cast isn't clean (e.g. '123a' -> 123 or '' -> 0).
  # Set this to :raise to raise an error on unclean casts.
  mattr_accessor :dynamic_finder_type_cast_error

  # defines the behavior when nil or empty array arguments passed into dynamic
  # finders. The default (:log) logs a warning if the finder is not scoped and
  # if *all* arguments are nil/[], e.g.
  #   Thing.find_by_foo_and_bar(nil, nil)       # warning
  #   Other.find_by_baz([])                     # warning
  #   Another.find_all_by_a_and_b(123, nil)     # ok
  #   ThisThing.some_scope.find_by_whatsit(nil) # ok
  # Set this to :raise to raise an exception.
  mattr_accessor :dynamic_finder_nil_arguments_error

  def self.active_record_foreign_key_check(name, type, options)
    if name.to_s =~ /_id\z/ && type.to_s == 'integer' && options[:limit].to_i < 8
      raise ArgumentError, "All foreign keys need to be 8-byte integers. #{name} looks like a foreign key to me, please add this option: `:limit => 8`"
    end
  end

  def self.redis
    return @redis if @redis
    # create the redis cluster connection using config/redis.yml
    redis_settings = Setting.from_config('redis')
    raise("Redis is not enabled for this install") if redis_settings.blank?
    Bundler.require 'redis'
    if redis_settings.is_a?(Array)
      redis_settings = { :servers => redis_settings }
    end
    # convert string addresses to options hash, and disable redis-cache's built-in marshalling code
    redis_settings[:servers].map! { |s|
      ::Redis::Factory.convert_to_redis_client_options(s).merge(:marshalling => false)
    }
    @redis = ::Redis::Factory.create(redis_settings[:servers])
    if redis_settings[:database].present?
      @redis.select(redis_settings[:database])
    end
    @redis
  end

  def self.redis_enabled?
    @redis_enabled ||= Setting.from_config('redis').present?
  end

  def self.reconnect_redis
    @redis = nil
    if Rails.cache && Rails.cache.respond_to?(:reconnect)
      Canvas::Redis.handle_redis_failure(nil) do
        Rails.cache.reconnect
      end
    end
  end

  def self.cache_store_config
    cache_store_config = {
      'cache_store' => 'mem_cache_store',
    }.merge(Setting.from_config('cache_store') || {})
    config = nil
    case cache_store_config.delete('cache_store')
    when 'mem_cache_store'
      cache_store_config['namespace'] ||= cache_store_config['key']
      servers = cache_store_config['servers'] || (Setting.from_config('memcache'))
      if servers
        config = :mem_cache_store, servers, cache_store_config
      end
    when 'redis_store'
      Bundler.require 'redis'
      Canvas::Redis.patch
      # merge in redis.yml, but give precedence to cache_store.yml
      #
      # the only options currently supported in redis-cache are the list of
      # servers, not key prefix or database names.
      cache_store_config = (Setting.from_config('redis') || {}).merge(cache_store_config)
      cache_store_config['key_prefix'] ||= cache_store_config['key']
      servers = cache_store_config['servers']
      config = :redis_store, servers
    end
    unless config
      config = :nil_store
    end
    config
  end

  # `sample` reports KB, not B
  if File.directory?("/proc")
    # linux w/ proc fs
    LINUX_PAGE_SIZE = (size = `getconf PAGESIZE`.to_i; size > 0 ? size : 4096)
    LINUX_HZ = 100.0 # this isn't always true, but it usually is
    def self.sample_memory
      s = File.read("/proc/#{Process.pid}/statm").to_i rescue 0
      s * LINUX_PAGE_SIZE / 1024
    end
    # returns [ utime, stime ], both in seconds
    def self.sample_cpu_time
      a = File.read("/proc/#{Process.pid}/stat").split(" ") rescue nil
      [ a[13].to_f / LINUX_HZ, a[14].to_f / LINUX_HZ] if a && a.length >= 15
    end
  else
    # generic unix solution
    def self.sample_memory
      # hmm this is actually resident set size, doesn't include swapped-to-disk
      # memory.
      `ps -o rss= -p #{Process.pid}`.to_i
    end
    def self.sample_cpu_time
      # TODO: use ps to grab this
      [ 0, 0 ]
    end
  end

  # can be called by plugins to allow reloading of that plugin in dev mode
  # pass in the path to the plugin directory
  # e.g., in the vendor/plugins/<plugin_name>/init.rb:
  #     Canvas.reloadable_plugin(File.dirname(__FILE__))
  def self.reloadable_plugin(dirname)
    return unless Rails.env.development?
    base_path = File.expand_path(dirname)
    ActiveSupport::Dependencies.load_once_paths.reject! { |p|
      p[0, base_path.length] == base_path
    }
  end

  def self.revision
    return @revision unless @revision.nil?
    if File.file?(Rails.root+"VERSION")
      @revision = File.readlines(Rails.root+"VERSION").first.try(:strip)
    end
    @revision ||= false
  end

  # protection against calling external services that could timeout or misbehave.
  # we keep track of timeouts in redis, and if a given service times out more
  # than X times before the redis key expires in Y seconds (reset on each
  # failure), we stop even trying to contact the service until the Y seconds
  # passes.
  #
  # if redis isn't enabled, we'll still apply the timeout, but we won't track failures.
  #
  # all the configurable params have service-specific Settings with fallback to
  # generic Settings.
  def self.timeout_protection(service_name)
    redis_key = "service:timeouts:#{service_name}"
    if Canvas.redis_enabled?
      cutoff = (Setting.get_cached("service_#{service_name}_cutoff", nil) || Setting.get_cached("service_generic_cutoff", 3.to_s)).to_i
      error_count = Canvas.redis.get(redis_key)
      if error_count.to_i >= cutoff
        Rails.logger.error("Skipping service call due to error count: #{service_name} #{error_count}")
        return
      end
    end

    timeout = (Setting.get_cached("service_#{service_name}_timeout", nil) || Setting.get_cached("service_generic_timeout", 15.seconds.to_s)).to_f
    Timeout.timeout(timeout) do
      yield
    end
  rescue Timeout::Error => e
    ErrorReport.log_exception(:service_timeout, e)
    if Canvas.redis_enabled?
      error_ttl = (Setting.get_cached("service_#{service_name}_error_ttl", nil) || Setting.get_cached("service_generic_error_ttl", 1.minute.to_s)).to_i
      Canvas.redis.pipelined do
        Canvas.redis.incrby(redis_key, 1)
        Canvas.redis.expire(redis_key, error_ttl)
      end
    end
    return nil
  end
end
