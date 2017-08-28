class AddForeignKeyIndexes9 < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :conversation_batches, :root_conversation_message_id, algorithm: :concurrently
  end
end
