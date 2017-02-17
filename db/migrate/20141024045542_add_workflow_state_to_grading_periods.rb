class AddWorkflowStateToGradingPeriods < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :grading_periods, :workflow_state, :string
  end
end
