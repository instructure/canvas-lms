class ClearRailsCache < ActiveRecord::Migration
  tag :predeploy, :postdeploy

  def up
    Rails.cache.clear
  end

  def down
  end
end
