class RemoveExtraneousConversationTags < ActiveRecord::Migration
  def self.up
    DataFixup::RemoveExtraneousConversationTags.send_later_if_production(:run)

    # incidentally, when someone deletes all the messages from their CP, its
    # tags should get cleared out, but a bug prevented that from happening
    # (that's also fixed in this commit).
    execute "UPDATE conversation_participants SET tags = '' WHERE last_message_at IS NULL AND message_count = 0 AND tags <> ''"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
