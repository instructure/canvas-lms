class AddConversationMessageProperties < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_messages, :has_attachments, :boolean
    add_column :conversation_messages, :has_media_objects, :boolean
  end

  def self.down
    remove_column :conversation_messages, :has_attachments
    remove_column :conversation_messages, :has_media_objects
  end
end
