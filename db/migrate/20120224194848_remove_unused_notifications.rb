class RemoveUnusedNotifications < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    Notification.update_all({:category => 'Other'}, :category => 'Message')
    Notification.delete_all(:category => ['Files', 'Student Message'])
  end

  def self.down
  end
end
