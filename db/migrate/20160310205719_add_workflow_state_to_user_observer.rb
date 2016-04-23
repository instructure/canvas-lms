class AddWorkflowStateToUserObserver < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :user_observers, :workflow_state, :string, default: 'active', null: false
    add_index :user_observers, :workflow_state
  end
end
