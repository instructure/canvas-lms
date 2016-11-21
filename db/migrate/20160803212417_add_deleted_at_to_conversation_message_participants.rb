class AddDeletedAtToConversationMessageParticipants < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :conversation_message_participants, :deleted_at, :datetime
    add_index :conversation_message_participants, :deleted_at, algorithm: :concurrently
  end
end
