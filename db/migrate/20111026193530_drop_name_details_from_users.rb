class DropNameDetailsFromUsers < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if User.column_names.include?('given_name')
      remove_column :users, :suffix
      remove_column :users, :surname
      remove_column :users, :given_name
      remove_column :users, :title
    end
  end

  def self.down
  end
end
