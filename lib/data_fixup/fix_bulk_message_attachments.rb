module DataFixup::FixBulkMessageAttachments
  def self.run
    ConversationBatch.preload(:root_conversation_message).find_each do |batch|
      root_message = batch.root_conversation_message
      next unless root_message.has_attachments?
      messages = ConversationMessage.find(batch.conversation_message_ids)
      messages.each do |message|
        message.attachment_ids = root_message.attachment_ids
        message.save!
      end
    end
  end
end
