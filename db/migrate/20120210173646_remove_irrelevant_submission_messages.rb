class RemoveIrrelevantSubmissionMessages < ActiveRecord::Migration
  def self.up
    if supports_ddl_transactions?
      commit_db_transaction
      decrement_open_transactions while open_transactions > 0
    end

    # destroy any submission messages where none of the commenters are
    # participants in the conversation. in production, this will remove about
    # 7k rows
    ConversationMessage.destroy_all(<<-CONDITIONS)
      asset_id IS NOT NULL
      AND id NOT IN (
        SELECT DISTINCT cm.id
        FROM conversation_messages cm,
          conversation_participants cp,
          submission_comments sc
        WHERE 
          cm.asset_id = sc.submission_id
          AND cp.conversation_id = cm.conversation_id
          AND sc.author_id = cp.user_id
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