module DataFixup::RemoveExtraneousConversationTags
  def self.run
    # non-deleted CPs in a private conversation should usually have the same
    # tags. if they don't, they may need fixing (not necessarily ... the tags
    # are a function of the non-deleted messages).
    conditions = <<-COND
      private_hash IS NOT NULL AND (
        SELECT COUNT(DISTINCT tags)
        FROM conversation_participants
        WHERE conversation_id = conversations.id
      ) > 1
    COND
    Conversation.where(conditions).find_each do |c|
      fix_private_conversation!(c)
    end
  end

  def self.fix_private_conversation!(c)
    return if c.tags.empty? || !c.private?
    allowed_tags = c.current_context_strings(1)
    Conversation.transaction do
      c.lock!
      c.update_attribute :tags, c.tags & allowed_tags
      c.conversation_participants(:include => :user).each do |cp|
        next unless cp.user
        tags_to_remove = cp.tags - c.tags
        next if tags_to_remove.empty?
        cp.update_attribute :tags, cp.tags & c.tags
        cp.conversation_message_participants.tagged(*tags_to_remove).each do |cmp|
          new_tags = cmp.tags & c.tags
          new_tags = cp.tags if new_tags.empty?
          cmp.update_attribute :tags, new_tags
        end
      end
    end
  end
end
