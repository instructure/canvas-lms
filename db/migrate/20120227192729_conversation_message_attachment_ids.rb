class ConversationMessageAttachmentIds < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversation_messages, :attachment_ids, :text
  end

  def self.down
    remove_column :conversation_messages, :attachment_ids
  end
end
