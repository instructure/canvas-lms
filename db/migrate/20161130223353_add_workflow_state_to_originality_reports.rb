class AddWorkflowStateToOriginalityReports < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :originality_reports, :workflow_state, :string, null: false, default: 'pending'
    add_index :originality_reports, [:workflow_state]
  end
end
