class AddIndexOnDelayedMessagesNotificationPolicy < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :delayed_messages, :notification_policy_id, concurrently: true
  end

  def self.down
    remove_index :delayed_messages, :notification_policy_id
  end
end
