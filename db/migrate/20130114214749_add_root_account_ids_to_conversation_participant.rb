class AddRootAccountIdsToConversationParticipant < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_participants, :root_account_ids, :text
  end

  def self.down
    remove_column :conversation_participants, :root_account_ids
  end
end
