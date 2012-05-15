class MoveMigrationNotificationsToSeparateCategory < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    Notification.update_all({ :category => 'Migration' }, 
                            { :name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed'] })
  end

  def self.down
    Notification.update_all({ :category => 'Other' }, 
                            { :name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed'] })
  end
end
