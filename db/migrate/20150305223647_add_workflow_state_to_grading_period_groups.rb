class AddWorkflowStateToGradingPeriodGroups < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def up
    unless column_exists?(:grading_period_groups, :workflow_state)
      add_column :grading_period_groups, :workflow_state, :string
    end
    GradingPeriodGroup.where(workflow_state: nil).find_ids_in_batches do |ids|
      GradingPeriodGroup.where(id: ids).update_all(workflow_state: 'active')
    end
    change_column_default :grading_period_groups, :workflow_state, 'active'
    add_index :grading_period_groups, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :grading_period_groups, :workflow_state
  end
end
