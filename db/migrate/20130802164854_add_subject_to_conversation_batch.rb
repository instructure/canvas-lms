class AddSubjectToConversationBatch < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_batches, :subject, :string
  end

  def self.down
    remove_column :conversation_batches, :subject
  end
end
