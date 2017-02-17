class RemoveUnusedNotificationPolicies < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    ids = Notification.where(:category => ['Student Message', 'Files']).pluck(:id)
    NotificationPolicy.where(:notification_id => ids).delete_all
  end

  def self.down
  end
end
