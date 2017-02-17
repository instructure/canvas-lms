class DropBroadcastFromNotificationPolicies < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :notification_policies, :broadcast
  end

  def down
    add_column :notification_policies, :broadcast, :boolean, null: false, default: true
  end
end
