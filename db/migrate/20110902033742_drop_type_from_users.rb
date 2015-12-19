class DropTypeFromUsers < ActiveRecord::Migration
  tag :predeploy

  def self.up
    remove_index :users, :type
    remove_column :users, :type
  end

  def self.down
    add_column :users, :type, :string
    add_index :users, :type
  end
end
