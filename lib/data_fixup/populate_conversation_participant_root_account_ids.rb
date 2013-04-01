module DataFixup::PopulateConversationParticipantRootAccountIds
  def self.run
    target = %w{MySQL Mysql2}.include?(ConversationParticipant.connection.adapter_name) ? 'conversation_participants.root_account_ids' : 'root_account_ids'
    scope = ConversationParticipant.scoped(:conditions => {:root_account_ids => nil})
    scope = scope.scoped(:joins => :conversation, :conditions => "conversations.root_account_ids IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      ConversationParticipant.update_all("#{target}=conversations.root_account_ids",
                       ["conversation_participants.id>=? AND conversation_participants.id <=?", min, max])
    end
  end
end
