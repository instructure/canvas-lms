class AddGroupToBatchConversations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_batches, :group, :boolean
  end

  def self.down
    remove_column :conversation_batches, :group
  end
end
