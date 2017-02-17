class AddReplyToNameToMessages < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :messages, :reply_to_name, :string
  end

  def self.down
    remove_column :messages, :reply_to_name
  end
end
