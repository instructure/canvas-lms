class AddGroupRootAccount < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :groups, :root_account_id, :integer, :limit => 8

    update("UPDATE #{Group.quoted_table_name} SET root_account_id = (SELECT COALESCE(accounts.root_account_id, accounts.id) FROM #{Account.quoted_table_name} WHERE groups.account_id = accounts.id)")
  end

  def self.down
    remove_column :groups, :root_account_id
  end
end

