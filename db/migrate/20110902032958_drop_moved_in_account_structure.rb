class DropMovedInAccountStructure < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :users, :moved_in_account_structure
    remove_column :users, :moved_in_account_structure
    remove_index :courses, [:moved_in_account_structure, :updated_at]
    remove_column :courses, :moved_in_account_structure
    remove_column :accounts, :moved_in_account_structure
  end

  def self.down
    add_column :accounts, :moved_in_account_structure, :boolean, :default => true
    add_column :courses, :moved_in_account_structure, :boolean, :default => true
    add_index :courses, [:moved_in_account_structure, :updated_at]
    add_column :users, :moved_in_account_structure, :boolean, :default => true
    add_index :users, :moved_in_account_structure
  end
end
