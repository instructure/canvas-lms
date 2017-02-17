class ChangeGroupWorkflowStates < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    Group.where(workflow_state: ['closed', 'completed']).update_all(workflow_state: 'available')
  end
end
