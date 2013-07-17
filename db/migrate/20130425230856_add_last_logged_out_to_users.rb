class AddLastLoggedOutToUsers < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :users, :last_logged_out, :timestamp
  end

  def self.down
    remove_column :users, :last_logged_out
  end
end
