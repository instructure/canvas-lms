class AddConversationBatches < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :conversation_batches do |t|
      t.string :workflow_state
      t.integer :user_id, :limit => 8
      t.text :recipient_ids
      t.integer :root_conversation_message_id, :limit => 8
      t.text :conversation_message_ids
      t.text :tags
      t.timestamps null: true
    end
    add_index :conversation_batches, [:user_id, :workflow_state]
  end

  def self.down
    drop_table :conversation_batches
  end
end
