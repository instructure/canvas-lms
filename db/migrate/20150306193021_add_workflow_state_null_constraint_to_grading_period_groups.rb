class AddWorkflowStateNullConstraintToGradingPeriodGroups < ActiveRecord::Migration
  tag :predeploy

  def up
    change_column :grading_period_groups, :workflow_state, :string, :null => false
  end

  def down
    change_column :grading_period_groups, :workflow_state, :string, :null => true
  end
end
