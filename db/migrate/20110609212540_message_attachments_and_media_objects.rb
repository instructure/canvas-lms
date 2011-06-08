class MessageAttachmentsAndMediaObjects < ActiveRecord::Migration
  def self.up
    add_column :conversations, :has_attachments, :boolean
    add_column :conversations, :has_media_objects, :boolean
    add_column :conversation_participants, :has_attachments, :boolean
    add_column :conversation_participants, :has_media_objects, :boolean
  end

  def self.down
    drop_column :conversations, :has_attachments
    drop_column :conversations, :has_media_objects
    drop_column :conversation_participants, :has_attachments
    drop_column :conversation_participants, :has_media_objects
  end
end
