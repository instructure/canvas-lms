class RemoveExtraneousConversationTags < ActiveRecord::Migration
  def self.up
    # non-deleted CPs in a private conversation should usually have the same
    # tags. if they don't, they may need fixing (not necessarily ... the tags
    # are a function of the non-deleted messages).
    Conversation.connection.select_all(<<-SQL).
      SELECT id 
      FROM conversations
      WHERE private_hash IS NOT NULL
        AND (
          SELECT COUNT(DISTINCT tags)
          FROM conversation_participants
          WHERE conversation_id = conversations.id
        ) > 1
    SQL
    map{ |r| r["id"] }.each_slice(1000) do |ids|
      Conversation.send_later_if_production_enqueue_args(:batch_sanitize_context_tags!, {
        :priority => Delayed::LOWER_PRIORITY,
        :max_attempts => 1,
        :strand => "sanitize_conversation_context_tags"
      }, ids)
    end
    
    # incidentally, when someone deletes all the messages from their CP, its
    # tags should get cleared out, but a bug prevented that from happening
    # (that's also fixed in this commit).
    execute "UPDATE conversation_participants SET tags = '' WHERE last_message_at IS NULL AND message_count = 0 AND tags <> ''"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
