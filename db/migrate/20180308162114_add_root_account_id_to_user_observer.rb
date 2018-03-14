class AddRootAccountIdToUserObserver < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :user_observers, :root_account_id, :integer, :limit => 8
    add_index :user_observers, [:user_id, :observer_id, :root_account_id], :unique => true,
      :name => "index_user_observers_on_user_id_and_observer_id_and_ra", :algorithm => :concurrently
    remove_index :user_observers, [:user_id, :observer_id]
  end

  def down
    remove_column :user_observers, :root_account_id
    add_index :user_observers, [:user_id, :observer_id], :unique => true, :algorithm => :concurrently
  end
end
