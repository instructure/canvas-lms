class AddWorkflowStateToQuizQuestion < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :quiz_questions, :workflow_state, :string
  end

  def self.down
    remove_column :quiz_questions, :workflow_state
  end
end
