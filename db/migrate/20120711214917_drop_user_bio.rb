class DropUserBio < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :users, :bio
  end

  def self.down
    add_column :users, :bio, :text
  end
end
