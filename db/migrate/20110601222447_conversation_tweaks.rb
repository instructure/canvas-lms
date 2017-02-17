class ConversationTweaks < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_participants, :last_authored_at, :datetime
  end

  def self.down
    remove_column :conversation_participants, :last_authored_at
  end
end
