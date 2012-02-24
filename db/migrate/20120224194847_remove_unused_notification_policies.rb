class RemoveUnusedNotificationPolicies < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    ids = Notification.find(:all, :select => 'id', :conditions => { :category => ['Student Message', 'Files']}).map(&:id)
    NotificationPolicy.delete_all(:notification_id => ids)
  end

  def self.down
  end
end
