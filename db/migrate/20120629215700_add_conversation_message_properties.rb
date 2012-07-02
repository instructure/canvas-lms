class AddConversationMessageProperties < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversation_messages, :has_attachments, :boolean, :default => false
    add_column :conversation_messages, :has_media_objects, :boolean, :default => false
  end

  def self.down
    remove_column :conversation_messages, :has_attachments
    remove_column :conversation_messages, :has_media_objects
  end
end
