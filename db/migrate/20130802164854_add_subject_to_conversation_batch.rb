class AddSubjectToConversationBatch < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_column :conversation_batches, :subject, :string
  end

  def self.down
    remove_column :conversation_batches, :subject
  end
end
