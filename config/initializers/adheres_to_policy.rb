require 'adheres_to_policy'

ActiveRecord::Base.send :extend, AdheresToPolicy::ClassMethods

module AdheresToPolicy::InstanceMethods

  # Override the adheres_to_policy permission_cache_key for to make it shard aware.
  def permission_cache_key_for_with_sharding(user, session, right)
    Shard.default.activate do
      permission_cache_key_for_without_sharding(user, session, right)
    end
  end
  alias_method_chain :permission_cache_key_for, :sharding

end
