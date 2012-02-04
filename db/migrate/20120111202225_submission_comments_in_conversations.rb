class SubmissionCommentsInConversations < ActiveRecord::Migration
  def self.up
    add_column :conversation_messages, :asset_id, :integer, :limit => 8
    add_column :conversation_messages, :asset_type, :string
    if adapter_name == 'PostgreSQL'
      execute("CREATE INDEX index_conversation_messages_on_asset_id_and_asset_type ON conversation_messages (asset_id, asset_type) WHERE asset_id IS NOT NULL")
    else
      add_index :conversation_messages, [:asset_id, :asset_type]
    end
  end

  def self.down
    remove_column :conversation_messages, :asset_id
    remove_column :conversation_messages, :asset_type
  end
end
