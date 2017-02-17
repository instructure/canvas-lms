class AddUserNoteToConversationBatch < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_batches, :generate_user_note, :boolean
  end

  def self.down
    remove_column :conversation_batches, :generate_user_note
  end
end
