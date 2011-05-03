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
    @redis = ::Redis::Factory.create(redis_settings)
  end
end
