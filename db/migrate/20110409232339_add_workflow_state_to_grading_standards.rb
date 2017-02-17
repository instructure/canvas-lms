class AddWorkflowStateToGradingStandards < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :grading_standards, :workflow_state, :string
    GradingStandard.update_all(:workflow_state => 'active')
  end

  def self.down
    remove_column :grading_standards, :workflow_state
  end
end
