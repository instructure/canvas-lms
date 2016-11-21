class RemoveExtraneousConversationTags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::RemoveExtraneousConversationTags.send_later_if_production(:run)

    # incidentally, when someone deletes all the messages from their CP, its
    # tags should get cleared out, but a bug prevented that from happening
    # (that's also fixed in this commit).
    ConversationParticipant.where(last_message_at: nil, message_count: 0).where("tags<>''").update_all(tags: '')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
