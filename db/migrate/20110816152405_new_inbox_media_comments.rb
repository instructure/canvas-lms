class NewInboxMediaComments < ActiveRecord::Migration
  def self.up
    add_column :conversation_messages, :media_comment_id, :string
    add_column :conversation_messages, :media_comment_type, :string
  end

  def self.down
    remove_column :conversation_messages, :media_comment_id
    remove_column :conversation_messages, :media_comment_type
  end
end
