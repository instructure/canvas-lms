class AddWorkflowStateToAccountAuthorizationConfigs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :account_authorization_configs, :workflow_state, :string, default: 'active', null: false
    add_index :account_authorization_configs, :workflow_state
  end
end
