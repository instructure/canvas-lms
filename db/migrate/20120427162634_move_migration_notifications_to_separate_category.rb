class MoveMigrationNotificationsToSeparateCategory < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    Notification.where(:name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed']).
        update_all(:category => 'Migration')
  end

  def self.down
    Notification.where(:name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed']).
        update_all(:category => 'Other')
  end
end
