class DropAccountType < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :accounts, [:id, :type]
    remove_index :accounts, :type
    remove_column :accounts, :type
  end

  def self.down
    add_column :accounts, :type, :string
    add_index :accounts, :type
    add_index :accounts, [:id, :type]
  end
end
