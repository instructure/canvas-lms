class AddBioToUser < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :users, :bio, :text
  end

  def self.down
    remove_column :users, :bio, :text
  end
end
