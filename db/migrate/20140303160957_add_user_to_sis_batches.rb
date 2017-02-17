class AddUserToSisBatches < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :sis_batches, :user_id, :integer, :limit => 8
    add_foreign_key :sis_batches, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key :sis_batches, :users
    remove_column :sis_batches, :user_id
  end
end
