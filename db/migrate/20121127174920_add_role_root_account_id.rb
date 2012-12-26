class AddRoleRootAccountId < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :roles, :root_account_id, :integer, :limit => 8
    add_index :roles, [:root_account_id], :name => "index_roles_on_root_account_id"
  end

  def self.down
    remove_column :roles, :root_account_id
  end
end
