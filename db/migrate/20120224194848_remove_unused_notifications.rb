class RemoveUnusedNotifications < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    return unless Shard.current.default?
    Notification.where(:category => 'Message').update_all(:category => 'Other')
    Notification.where(:category => ['Files', 'Student Message']).delete_all
  end

  def self.down
  end
end
