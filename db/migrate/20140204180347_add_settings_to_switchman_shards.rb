class AddSettingsToSwitchmanShards < ActiveRecord::Migration
  tag :predeploy

  def up
    add_column :switchman_shards, :settings, :text
  end

  def down
    remove_column :switchman_shards, :settings
  end
end
