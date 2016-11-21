class ClearRailsCache < ActiveRecord::Migration[4.2]
  tag :predeploy

  # note that if you have any environments that are "split" somehow -
  # sharing a database, or created from a snapshot of a database,
  # or have non-connected cache servers - you'll need to manually
  # clear the cache in each of them.
  def up
    Rails.cache.clear if Shard.current.default?
  end

  def down
  end
end
