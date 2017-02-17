class AddTurnitinHostToAccounts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :accounts, :turnitin_host, :string
  end

  def self.down
    remove_column :accounts, :turnitin_host
  end
end
