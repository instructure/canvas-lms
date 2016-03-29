class AddWorkflowStateToDeveloperKeys < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :developer_keys, :workflow_state, :string, null: false, default: 'active'
  end
end
