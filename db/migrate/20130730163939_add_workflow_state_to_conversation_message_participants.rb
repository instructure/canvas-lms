class AddWorkflowStateToConversationMessageParticipants < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversation_message_participants, :workflow_state, :string
  end

  def self.down
    remove_column :conversation_message_participants, :workflow_state
  end
end
