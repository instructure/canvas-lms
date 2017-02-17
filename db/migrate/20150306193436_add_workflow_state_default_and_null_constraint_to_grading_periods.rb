class AddWorkflowStateDefaultAndNullConstraintToGradingPeriods < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    GradingPeriod.where(workflow_state: nil).find_ids_in_batches do |ids|
      GradingPeriod.where(id: ids).update_all(workflow_state: 'active')
    end
    change_column :grading_periods, :workflow_state, :string, :default => 'active', :null => false
    add_index :grading_periods, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_index :grading_periods, :workflow_state
    change_column :grading_periods, :workflow_state, :string, :default => nil, :null => true
  end
end
