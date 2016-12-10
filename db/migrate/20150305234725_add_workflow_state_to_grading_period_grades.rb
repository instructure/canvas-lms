class AddWorkflowStateToGradingPeriodGrades < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    unless column_exists?(:grading_period_grades, :workflow_state)
      add_column :grading_period_grades, :workflow_state, :string
    end
    GradingPeriodGrade.where(workflow_state: nil).find_ids_in_batches do |ids|
      GradingPeriodGrade.where(id: ids).update_all(workflow_state: 'active')
    end
    change_column_default :grading_period_grades, :workflow_state, 'active'
    add_index :grading_period_grades, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :grading_period_grades, :workflow_state
  end
end
