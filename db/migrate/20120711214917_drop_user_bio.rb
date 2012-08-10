class DropUserBio < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :users, :bio
  end

  def self.down
    add_column :users, :bio, :text
  end
end
