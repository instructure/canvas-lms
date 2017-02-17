class ChangeMessagesUrlToText < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    change_column :messages, :url, :text
  end

  def self.down
    change_column :messages, :url, :string
  end
end
