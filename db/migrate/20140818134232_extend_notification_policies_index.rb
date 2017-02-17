class ExtendNotificationPoliciesIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    NotificationPolicy.select([:communication_channel_id, :notification_id]).
        group(:communication_channel_id, :notification_id).
        having("COUNT(*) > 1").find_each do |policy|
      scope = NotificationPolicy.where(communication_channel_id: policy.communication_channel_id, notification_id: policy.notification_id)
      keeper = scope.order(:created_at).first
      to_delete_scope = scope.where("id<>?", keeper)
      DelayedMessage.where(notification_policy_id: to_delete_scope).update_all(notification_policy_id: keeper.id)
      to_delete_scope.delete_all
    end
    add_index :notification_policies, [:communication_channel_id, :notification_id], unique: true, algorithm: :concurrently, name: 'index_notification_policies_on_cc_and_notification_id'
    remove_index :notification_policies, :communication_channel_id
  end

  def down
    add_index :notification_policies, :communication_channel_id, algorithm: :concurrently
    remove_index :notification_policies, name: 'index_notification_policies_on_cc_and_notification_id'
  end
end
