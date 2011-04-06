module Canvas
  # defines the behavior when a protected attribute is assigned to in mass
  # assignment. The default, and Rails' normal behavior, is to just :log. Set
  # this to :raise to raise an exception.
  mattr_accessor :protected_attribute_error

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
