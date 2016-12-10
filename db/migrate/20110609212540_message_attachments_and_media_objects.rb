class MessageAttachmentsAndMediaObjects < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversations, :has_attachments, :boolean
    add_column :conversations, :has_media_objects, :boolean
    add_column :conversation_participants, :has_attachments, :boolean
    add_column :conversation_participants, :has_media_objects, :boolean
  end

  def self.down
    remove_column :conversations, :has_attachments
    remove_column :conversations, :has_media_objects
    remove_column :conversation_participants, :has_attachments
    remove_column :conversation_participants, :has_media_objects
  end
end
