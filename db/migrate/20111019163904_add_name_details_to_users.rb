class AddNameDetailsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :title, :string
    add_column :users, :given_name, :string
    add_column :users, :surname, :string
    add_column :users, :suffix, :string
  end

  def self.down
    remove_column :users, :suffix
    remove_column :users, :surname
    remove_column :users, :given_name
    remove_column :users, :title
  end
end
