class DropBroadcastFromNotificationPolicies < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :notification_policies, :broadcast
  end

  def down
    add_column :notification_policies, :broadcast, :boolean, null: false, default: true
  end
end
