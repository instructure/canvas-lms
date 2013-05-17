module DataFixup::PopulateConversationMessageProperties

  def self.run
    ConversationMessage.where("forwarded_message_ids IS NULL").find_ids_in_batches do |ids|
      ConversationMessage.where(:id => ids).update_all(
        "has_attachments = (attachment_ids IS NOT NULL AND attachment_ids <> ''), " +
        "has_media_objects = (media_comment_id IS NOT NULL)")
    end

    # infer_defaults will set has_attachments/has_media_objects
    ConversationMessage.where("forwarded_message_ids IS NOT NULL").find_each do |message|
      message.save!
      next unless message.has_attachments? || message.has_media_objects?
      c = message.conversation
      c.has_attachments = message.has_attachments?
      c.has_media_objects = message.has_media_objects?
      c.save!
      # can't just blindly update cps, since it depends on which messages are
      # still visible in each
      message.conversation.conversation_participants.each { |cp|
        cp.update_cached_data!(:recalculate_count => false, :set_last_message_at => false, :regenerate_tags => false)
      }
    end
  end
end