class LabelConversations < ActiveRecord::Migration
  def self.up
    add_column :conversation_participants, :label, :string
  end

  def self.down
    drop_column :conversation_participants, :label
  end
end
