class DataFixup::PopulateConversationParticipantRootAccountIds
  def self.run
    target = %w{MySQL Mysql2}.include?(ConversationParticipant.connection.adapter_name) ? 'conversation_participants.root_account_ids' : 'root_account_ids'
    scope = ConversationParticipant.where(:root_account_ids => nil)
    scope = scope.joins(:conversation).where("conversations.root_account_ids IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      ConversationParticipant.where(:conversation_participants => { :id => min..max }).
          update_all("#{target}=conversations.root_account_ids")
    end
  end
end
