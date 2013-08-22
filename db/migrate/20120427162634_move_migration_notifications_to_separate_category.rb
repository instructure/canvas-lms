class MoveMigrationNotificationsToSeparateCategory < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    return unless Shard.current == Shard.default
    Notification.where(:name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed']).
        update_all(:category => 'Migration')
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.where(:name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed']).
        update_all(:category => 'Other')
  end
end
