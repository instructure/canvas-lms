module DataFixup::PopulateConversationMessageParticipantUserIds
  def self.run
    target = ConversationMessageParticipant.connection.adapter_name == 'MySQL' ? 'conversation_message_participants.user_id' : 'user_id'
    ConversationMessageParticipant.scoped(:conditions => {:user_id => nil}).find_ids_in_ranges do |min, max|
      scope = ConversationMessageParticipant.scoped(:joins => :conversation_participant)
      scope.update_all("#{target}=conversation_participants.user_id",
                       ["conversation_message_participants.id>=? AND conversation_message_participants.id <=?", min, max])
    end
  end
end
