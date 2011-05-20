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
    @redis = ::Redis::Factory.create(redis_settings[:servers])
    if redis_settings[:database].present?
      @redis.select(redis_settings[:database])
    end
    @redis
  end

  def self.redis_enabled?
    @redis_enabled ||= Setting.from_config('redis').present?
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
end
