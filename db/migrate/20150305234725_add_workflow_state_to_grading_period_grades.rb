class AddWorkflowStateToGradingPeriodGrades < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    unless column_exists?(:grading_period_grades, :workflow_state)
      add_column :grading_period_grades, :workflow_state, :string
    end
    change_column_default :grading_period_grades, :workflow_state, 'active'
    add_index :grading_period_grades, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :grading_period_grades, :workflow_state
  end
end
