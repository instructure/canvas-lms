class AddSubjectToConversations < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversations, :subject, :string
  end

  def self.down
    remove_column :conversations, :subject
  end
end
