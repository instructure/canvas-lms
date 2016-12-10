class AddMessageAccountId < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :messages, :root_account_id, :integer, :limit => 8
    add_column :delayed_messages, :root_account_id, :integer, :limit => 8

    add_index :messages, :root_account_id, :algorithm => :concurrently
    add_index :delayed_messages, [:communication_channel_id, :root_account_id, :workflow_state, :send_at], :algorithm => :concurrently, :name => "ccid_raid_ws_sa"
    remove_index :delayed_messages, :name => "ccid_ws_sa"
  end

  def self.down
    add_index :delayed_messages, [:communication_channel_id, :workflow_state, :send_at], :algorithm => :concurrently, :name => "ccid_ws_sa"
    remove_index :delayed_messages, :name => "ccid_raid_ws_sa"
    remove_index :messages, :column => :root_account_id

    remove_column :messages, :root_account_id
    remove_column :delayed_messages, :root_account_id
  end
end
