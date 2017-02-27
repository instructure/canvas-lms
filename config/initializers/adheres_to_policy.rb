require 'adheres_to_policy'

ActiveRecord::Base.singleton_class.include(AdheresToPolicy::ClassMethods)

module ShardAwarePermissionCacheKey
  # Override the adheres_to_policy permission_cache_key for to make it shard aware.
  def permission_cache_key(user, session, right)
    Shard.default.activate { super }
  end
end
AdheresToPolicy::InstanceMethods.prepend(ShardAwarePermissionCacheKey)
