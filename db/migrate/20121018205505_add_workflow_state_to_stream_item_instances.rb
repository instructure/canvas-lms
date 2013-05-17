class AddWorkflowStateToStreamItemInstances < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :stream_item_instances, :workflow_state, :string
  end

  def self.down
    remove_column :stream_item_instances, :workflow_state
  end
end
