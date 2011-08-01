class MessageForwards < ActiveRecord::Migration
  def self.up
    add_column :conversation_messages, :forwarded_message_ids, :text
  end

  def self.down
    drop_column :conversation_messages, :forwarded_message_ids
  end
end
