module DataFixup::PopulateConversationMessageParticipantUserIds
  def self.run
    ConversationMessageParticipant.where(:user_id => nil).find_ids_in_ranges do |min, max|
      scope = ConversationMessageParticipant.joins(:conversation_participant)
      scope.where(:user_id => nil, :conversation_message_participants => { :id => min..max }).
          update_all("user_id=conversation_participants.user_id")
    end
  end
end
