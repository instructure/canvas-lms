class AddGroupRootAccount < ActiveRecord::Migration
  def self.up
    add_column :groups, :root_account_id, :integer, :limit => 8

    Group.connection.execute("UPDATE groups SET root_account_id = (SELECT COALESCE(accounts.root_account_id, accounts.id) FROM accounts WHERE groups.account_id = accounts.id)")
  end

  def self.down
    remove_column :groups, :root_account_id
  end
end

