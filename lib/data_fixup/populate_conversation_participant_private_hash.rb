module DataFixup::PopulateConversationParticipantPrivateHash
  def self.run
    target = %w{MySQL Mysql2}.include?(ConversationParticipant.connection.adapter_name) ? 'conversation_participants.private_hash' : 'private_hash'
    scope = ConversationParticipant.scoped(:conditions => {:private_hash => nil})
    scope = scope.scoped(:joins => :conversation, :conditions => "conversations.private_hash IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      ConversationParticipant.update_all("#{target}=conversations.private_hash",
                                         ["conversation_participants.id>=? AND conversation_participants.id <=?", min, max])
    end
  end
end
