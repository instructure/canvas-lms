class RemoveDuplicateSubmissionMessages < ActiveRecord::Migration
  def self.up
    if supports_ddl_transactions?
      commit_db_transaction
      decrement_open_transactions while open_transactions > 0
    end

    # destroy rather than delete so that callbacks happen 
    ConversationMessage.destroy_all(<<-CONDITIONS)
      asset_id IS NOT NULL
      AND id NOT IN (
        SELECT MIN(id)
        FROM conversation_messages
        WHERE asset_id IS NOT NULL
        GROUP BY conversation_id, asset_id
      )
    CONDITIONS

    if supports_ddl_transactions?
      increment_open_transactions
      begin_db_transaction
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end