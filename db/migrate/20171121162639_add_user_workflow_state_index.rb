class AddUserWorkflowStateIndex < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :users, :workflow_state, algorithm: :concurrently
  end
end
