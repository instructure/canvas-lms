module Canvas
  # defines the behavior when a protected attribute is assigned to in mass
  # assignment. The default, and Rails' normal behavior, is to just :log. Set
  # this to :raise to raise an exception.
  mattr_accessor :protected_attribute_error

  # defines the behavior when nil or empty array arguments passed into dynamic
  # finders. The default (:log) logs a warning if the finder is not scoped and
  # if *all* arguments are nil/[], e.g.
  #   Thing.find_by_foo_and_bar(nil, nil)       # warning
  #   Other.find_by_baz([])                     # warning
  #   Another.find_all_by_a_and_b(123, nil)     # ok
  #   ThisThing.some_scope.find_by_whatsit(nil) # ok
  # Set this to :raise to raise an exception.
  mattr_accessor :dynamic_finder_nil_arguments_error

  # defines extensions that could possibly be used, so that specs can move them to the
  # correct schemas for sharding
  mattr_accessor :possible_postgres_extensions
  self.possible_postgres_extensions = [:pg_collkey, :pg_trgm]

  def self.active_record_foreign_key_check(name, type, options)
    if name.to_s =~ /_id\z/ && type.to_s == 'integer' && options[:limit].to_i < 8
      raise ArgumentError, "All foreign keys need to be 8-byte integers. #{name} looks like a foreign key to me, please add this option: `:limit => 8`"
    end
  end

  def self.redis
    raise "Redis is not enabled for this install" unless Canvas.redis_enabled?
    @redis ||= begin
      settings = ConfigFile.load('redis')
      Canvas::RedisConfig.from_settings(settings).redis
    end
  end

  # Builds a redis object using a config hash in the format used by a couple
  # different config/*.yml files, like redis.yml, cache_store.yml and
  # delayed_jobs.yml
  def self.redis_from_config(redis_settings)
    RedisConfig.from_settings(redis_settings).redis
  end

  def self.redis_enabled?
    @redis_enabled ||= ConfigFile.load('redis').present?
  end

  def self.reconnect_redis
    @redis = nil
    if Rails.cache && Rails.cache.respond_to?(:reconnect)
      Canvas::Redis.handle_redis_failure(nil, "none") do
        Rails.cache.reconnect
      end
    end
  end

  def self.cache_store_config(rails_env = :current, nil_is_nil = true)
    rails_env = Rails.env if rails_env == :current
    cache_stores[rails_env]
  end

  def self.cache_stores
    unless @cache_stores
      # this method is called really early in the bootup process, and
      # autoloading might not be available yet, so we need to manually require
      # Config
      require_dependency 'lib/config_file'
      @cache_stores = {}
      configs = ConfigFile.load('cache_store', nil) || {}

      # sanity check the file
      unless configs.is_a?(Hash)
        raise "Invalid config/cache_store.yml: Root is not a hash. See comments in config/cache_store.yml.example"
      end

      non_hashes = configs.keys.select { |k| !configs[k].is_a?(Hash) }
      non_hashes.reject! { |k| configs[k].is_a?(String) && configs[configs[k]].is_a?(Hash) }
      raise "Invalid config/cache_store.yml: Some keys are not hashes: #{non_hashes.join(', ')}. See comments in config/cache_store.yml.example" unless non_hashes.empty?

      configs.each do |env, config|
        if config.is_a?(String)
          # switchman will treat strings as a link to another database server
          @cache_stores[env] = config
          next
        end
        config = {'cache_store' => 'mem_cache_store'}.merge(config)
        case config.delete('cache_store')
        when 'mem_cache_store'
          config['namespace'] ||= config['key']
          servers = config['servers'] || (ConfigFile.load('memcache', env))
          if servers
            @cache_stores[env] = :mem_cache_store, servers, config
          end
        when 'redis_store'
          Bundler.require 'redis'
          require_dependency 'canvas/redis'
          Canvas::Redis.patch
          # merge in redis.yml, but give precedence to cache_store.yml
          #
          # the only options currently supported in redis-cache are the list of
          # servers, not key prefix or database names.
          config = (ConfigFile.load('redis', env) || {}).merge(config)
          config_options = config.symbolize_keys.except(:key, :servers, :database)
          servers = config['servers']
          if servers
            servers = config['servers'].map { |s| Canvas::RedisConfig.url_to_redis_options(s).merge(config_options) }
            @cache_stores[env] = :redis_store, servers
          end
        when 'memory_store'
          @cache_stores[env] = :memory_store
        when 'nil_store'
          @cache_stores[env] = :null_store
        end
      end
      @cache_stores[Rails.env] ||= :null_store
    end
    @cache_stores
  end

  # `sample` reports KB, not B
  if File.directory?("/proc")
    # linux w/ proc fs
    LINUX_PAGE_SIZE = (size = `getconf PAGESIZE`.to_i; size > 0 ? size : 4096)
    def self.sample_memory
      s = File.read("/proc/#{Process.pid}/statm").to_i rescue 0
      s * LINUX_PAGE_SIZE / 1024
    end
  else
    # generic unix solution
    def self.sample_memory
      if Rails.env.test?
        0
      else
        # hmm this is actually resident set size, doesn't include swapped-to-disk
        # memory.
        `ps -o rss= -p #{Process.pid}`.to_i
      end
    end
  end

  # can be called by plugins to allow reloading of that plugin in dev mode
  # pass in the path to the plugin directory
  # e.g., in the vendor/plugins/<plugin_name>/init.rb:
  #     Canvas.reloadable_plugin(File.dirname(__FILE__))
  def self.reloadable_plugin(dirname)
    return unless Rails.env.development?
    base_path = File.expand_path(dirname)
    ActiveSupport::Dependencies.autoload_once_paths.reject! { |p|
      p[0, base_path.length] == base_path
    }
  end

  def self.revision
    return @revision if defined?(@revision)
    @revision = if File.file?(Rails.root+"VERSION")
      File.readlines(Rails.root+"VERSION").first.try(:strip)
    else
      nil
    end
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
  def self.timeout_protection(service_name, options={}, &block)
    timeout = (Setting.get("service_#{service_name}_timeout", nil) || options[:fallback_timeout_length] || Setting.get("service_generic_timeout", 15.seconds.to_s)).to_f

    if Canvas.redis_enabled?
      redis_key = "service:timeouts:#{service_name}"
      cutoff = (Setting.get("service_#{service_name}_cutoff", nil) || Setting.get("service_generic_cutoff", 3.to_s)).to_i
      error_ttl = (Setting.get("service_#{service_name}_error_ttl", nil) || Setting.get("service_generic_error_ttl", 1.minute.to_s)).to_i
      short_circuit_timeout(Canvas.redis, redis_key, timeout, cutoff, error_ttl, &block)
    else
      Timeout.timeout(timeout, &block)
    end
  rescue TimeoutCutoff => e
    Rails.logger.error("Skipping service call due to error count: #{service_name} #{e.error_count}")
    raise if options[:raise_on_timeout]
    return nil
  rescue Timeout::Error => e
    ErrorReport.log_exception(:service_timeout, e)
    raise if options[:raise_on_timeout]
    return nil
  end

  def self.short_circuit_timeout(redis, redis_key, timeout, cutoff, error_ttl)
    error_count = redis.get(redis_key)
    if error_count.to_i >= cutoff
      raise TimeoutCutoff.new(error_count)
    end

    begin
      Timeout.timeout(timeout) do
        yield
      end
    rescue Timeout::Error => e
      redis.incrby(redis_key, 1)
      redis.expire(redis_key, error_ttl)
      raise
    end
  end

  class TimeoutCutoff < Timeout::Error
    attr_accessor :error_count

    def initialize(error_count)
      @error_count = error_count
    end
  end
end
