class ChangeMessagesUrlToText < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    change_column :messages, :url, :text
  end

  def self.down
    change_column :messages, :url, :string
  end
end