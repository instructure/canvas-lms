class AddUniqueIndexToSettings < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    add_index :settings, :name, :unique => true
  end

  def self.down
    remove_index :settings, :name
  end
end
