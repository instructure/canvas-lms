class AddWorkflowStatesToTokensAndEndpoints < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :access_tokens, :workflow_state, :string
    change_column_default(:access_tokens, :workflow_state, 'active')
    DataFixup::BackfillNulls.run(AccessToken, :workflow_state, default_value: 'active')
    change_column_null(:access_tokens, :workflow_state, false)
    add_index :access_tokens, :workflow_state, algorithm: :concurrently

    add_column :notification_endpoints, :workflow_state, :string
    change_column_default(:notification_endpoints, :workflow_state, 'active')
    DataFixup::BackfillNulls.run(NotificationEndpoint, :workflow_state, default_value: 'active')
    change_column_null(:notification_endpoints, :workflow_state, false)
    add_index :notification_endpoints, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :access_tokens, :workflow_state
    remove_column :notification_endpoints, :workflow_state
  end
end
