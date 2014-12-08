class AddWorkflowStateToGradingPeriods < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :grading_periods, :workflow_state, :string
  end
end
