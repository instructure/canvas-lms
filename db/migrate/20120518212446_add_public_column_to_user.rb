class AddPublicColumnToUser < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :users, :public, :boolean
    User.reset_column_information
  end

  def self.down
    remove_column :users, :public
  end
end
