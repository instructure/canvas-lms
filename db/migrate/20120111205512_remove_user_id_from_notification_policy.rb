class RemoveUserIdFromNotificationPolicy < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_column :notification_policies, :user_id
  end

  def self.down
    add_column :notification_policies, :user_id, :integer, :limit => 8
    NotificationPolicy.update_all('user_id=(SELECT user_id FROM communication_channels WHERE communication_channels.id=communication_channel_id)')
  end
end
