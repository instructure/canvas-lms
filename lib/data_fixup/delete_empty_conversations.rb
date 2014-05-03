module DataFixup::DeleteEmptyConversations
  def self.run
    ConversationParticipant.where('message_count = 0 AND last_message_at IS NOT NULL').find_in_batches do |batch|
      ConversationParticipant.where(id: batch).update_all(last_message_at: nil)
    end
  end
end
