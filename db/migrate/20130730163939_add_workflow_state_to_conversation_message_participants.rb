class AddWorkflowStateToConversationMessageParticipants < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_message_participants, :workflow_state, :string
  end

  def self.down
    remove_column :conversation_message_participants, :workflow_state
  end
end
