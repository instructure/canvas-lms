class MoveContentExportNotificationsToMigrationCategory < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    Notification.update_all({ :category => 'Migration' }, 
                            { :name => ['Content Export Finished', 'Content Export Failed'] })
      
    # send immediate notifications only work if you DON'T have a policy for that notification
    ids = Notification.scoped(
      :select => :id,
      :conditions => { :category => 'Migration' }
    ).map(&:id)
    if ids.present?
      NotificationPolicy.destroy_all(:notification_id => ids)
    end
  end

  def self.down
    Notification.update_all({ :category => 'Other' }, 
                            { :name => ['Content Export Finished', 'Content Export Failed'] })
  end
end
