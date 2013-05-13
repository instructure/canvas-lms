module DataFixup::PopulateConversationMessageParticipantUserIds
  def self.run
    target = %w{MySQL Mysql2}.include?(ConversationMessageParticipant.connection.adapter_name) ? 'conversation_message_participants.user_id' : 'user_id'
    ConversationMessageParticipant.where(:user_id => nil).find_ids_in_ranges do |min, max|
      scope = ConversationMessageParticipant.joins(:conversation_participant)
      scope.where(:conversation_message_participants => { :id => min..max }).
          update_all("#{target}=conversation_participants.user_id")
    end
  end
end
