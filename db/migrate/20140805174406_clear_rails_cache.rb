class ClearRailsCache < ActiveRecord::Migration
  tag :predeploy, :postdeploy

  def up
    Rails.cache.clear if Shard.current.default?
  end

  def down
  end
end
