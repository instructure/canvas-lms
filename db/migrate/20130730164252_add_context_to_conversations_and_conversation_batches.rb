class AddContextToConversationsAndConversationBatches < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversations, :context_type, :string
    add_column :conversations, :context_id, :integer, :limit => 8

    add_column :conversation_batches, :context_type, :string
    add_column :conversation_batches, :context_id, :integer, :limit => 8
  end

  def self.down
    remove_columns :conversations, :context_type, :context_id
    remove_columns :conversation_batches, :context_type, :context_id
  end
end
