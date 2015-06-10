class AddWorkflowStateNullConstraintToGradingPeriodGrades < ActiveRecord::Migration
  tag :predeploy

  def up
    change_column :grading_period_grades, :workflow_state, :string, :null => false
  end

  def down
    change_column :grading_period_grades, :workflow_state, :string, :null => true
  end
end
