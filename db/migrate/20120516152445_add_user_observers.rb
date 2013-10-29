class AddUserObservers < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    create_table :user_observers do |t|
      t.integer :user_id, :limit => 8, :null => false
      t.integer :observer_id, :limit => 8, :null => false
    end
    add_index :user_observers, [:user_id, :observer_id], :unique => true
    add_index :user_observers, :observer_id

    # User#move_to_user already needed this, and now we do a second query there
    add_index :enrollments, [:associated_user_id], :algorithm => :concurrently, :where => "associated_user_id IS NOT NULL"
  end

  def self.down
    drop_table :user_observers
    remove_index :enrollments, :name => "index_enrollments_on_associated_user_id"
  end
end
