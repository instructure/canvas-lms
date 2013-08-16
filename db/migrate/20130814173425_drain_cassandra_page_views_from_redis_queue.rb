class DrainCassandraPageViewsFromRedisQueue < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    return unless PageView.cassandra?
    return if PageView.cassandra_uses_redis?

    # cassandra page views don't use a redis cache intermediary anymore, but they
    # did. pull any remaining page views off the cache and insert them into
    # cassandra
    PageView.send_later_if_production_enqueue_args(
      :process_cache_queue,
      singleton: "PageView.process_cache_queue:#{Shard.current.id}",
      max_attempts: 1)
  end

  def self.down
  end
end
