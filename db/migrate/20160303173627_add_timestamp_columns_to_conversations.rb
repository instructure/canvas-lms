class AddTimestampColumnsToConversations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :conversations, :updated_at, :timestamp
    add_column :conversation_participants, :updated_at, :timestamp
  end
end
