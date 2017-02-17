class AddBioToUser < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :users, :bio, :text
  end

  def self.down
    remove_column :users, :bio, :text
  end
end
