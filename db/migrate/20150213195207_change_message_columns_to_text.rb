class ChangeMessageColumnsToText < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    change_column :messages, :to, :text
    change_column :messages, :from, :text
  end

  def self.down
    change_column :messages, :to, :string
    change_column :messages, :from, :string
  end
end