class AddPublicColumnToUser < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :users, :public, :boolean
    User.reset_column_information
  end

  def self.down
    remove_column :users, :public
  end
end
