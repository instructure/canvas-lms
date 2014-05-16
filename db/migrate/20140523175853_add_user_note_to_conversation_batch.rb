class AddUserNoteToConversationBatch < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversation_batches, :generate_user_note, :boolean
  end

  def self.down
    remove_column :conversation_batches, :generate_user_note
  end
end
