class AddReplyToNameToMessages < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :messages, :reply_to_name, :string
  end

  def self.down
    remove_column :messages, :reply_to_name
  end
end
