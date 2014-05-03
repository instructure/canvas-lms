class RemoveIrrelevantSubmissionMessages < ActiveRecord::Migration
  disable_ddl_transaction!

  def self.up
    # destroy any submission messages where none of the commenters are
    # participants in the conversation. in production, this will remove about
    # 7k rows
    ConversationMessage.where(<<-CONDITIONS).destroy_all
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
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end