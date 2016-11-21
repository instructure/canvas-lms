require_dependency 'canvas/draft_state_validations'

module Canvas
  # defines the behavior when a protected attribute is assigned to in mass
  # assignment. The default, and Rails' normal behavior, is to just :log. Set
  # this to :raise to raise an exception.
  mattr_accessor :protected_attribute_error

  def self.active_record_foreign_key_check(name, type, options)
    if name.to_s =~ /_id\z/ && type.to_s == 'integer' && options[:limit].to_i < 8
      raise ArgumentError, <<-EOS
        All foreign keys need to be at least 8-byte integers. #{name}
        looks like a foreign key, please add this option: `:limit => 8`
      EOS
    end
  end

  def self.redis
    raise "Redis is not enabled for this install" unless Canvas.redis_enabled?
    @redis ||= begin
      Bundler.require 'redis'
      Canvas::Redis.patch
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
    if Rails.cache && Rails.cache.respond_to?(:reconnect)
      Canvas::Redis.handle_redis_failure(nil, "none") do
        Rails.cache.reconnect
      end
    end

    return unless @redis
    # We're sharing redis connections between Canvas.redis and Rails.cache,
    # so don't call reconnect on the cache too.
    return if Rails.cache.respond_to?(:data) && @redis.__getobj__ == Rails.cache.data
    @redis = nil
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
        raise <<-EOS
          Invalid config/cache_store.yml: Root is not a hash. See comments in
          config/cache_store.yml.example
        EOS
      end

      non_hashes = configs.keys.select { |k| !configs[k].is_a?(Hash) }
      non_hashes.reject! { |k| configs[k].is_a?(String) && configs[configs[k]].is_a?(Hash) }
      unless non_hashes.empty?
        raise <<-EOS
          Invalid config/cache_store.yml: Some keys are not hashes:
          #{non_hashes.join(', ')}. See comments in
          config/cache_store.yml.example
        EOS
      end

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
          # if cache and redis data are configured identically, we want to share connections
          if config == {} && env == Rails.env && Canvas.redis_enabled?
            # A bit of gymnastics to wrap an existing Redis::Store into an ActiveSupport::Cache::RedisStore
            store = ActiveSupport::Cache::RedisStore.new([])
            store.instance_variable_set(:@data, Canvas.redis.__getobj__)
            @cache_stores[env] = store
          else
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
  # e.g., in the vendor/plugins/<plugin_name>/init.rb or
  # gems/plugins/<plugin_name>/lib/<plugin_name>/engine.rb:
  #     Canvas.reloadable_plugin(File.dirname(__FILE__))
  def self.reloadable_plugin(dirname)
    return unless Rails.env.development?
    base_path = File.expand_path(dirname)
    base_path.gsub(%r{/lib/[^/]*$}, '')
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

  def self.installation_uuid
    installation_uuid = Setting.get("installation_uuid", "")
    if installation_uuid == ""
      installation_uuid = SecureRandom.uuid
      Setting.set("installation_uuid", installation_uuid)
    end
    installation_uuid
  end

  def self.timeout_protection_error_ttl(service_name)
    (Setting.get("service_#{service_name}_error_ttl", nil) || Setting.get("service_generic_error_ttl", 1.minute.to_s)).to_i
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
      error_ttl = timeout_protection_error_ttl(service_name)
      short_circuit_timeout(Canvas.redis, redis_key, timeout, cutoff, error_ttl, &block)
    else
      Timeout.timeout(timeout, &block)
    end
  rescue TimeoutCutoff => e
    Rails.logger.error("Skipping service call due to error count: #{service_name} #{e.error_count}")
    raise if options[:raise_on_timeout]
    return nil
  rescue Timeout::Error => e
    Canvas::Errors.capture_exception(:service_timeout, e)
    raise if options[:raise_on_timeout]
    return nil
  end

  def self.short_circuit_timeout(redis, redis_key, timeout, cutoff, error_ttl, &block)
    error_count = redis.get(redis_key)
    if error_count.to_i >= cutoff
      raise TimeoutCutoff.new(error_count)
    end

    begin
      Timeout.timeout(timeout, &block)
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
