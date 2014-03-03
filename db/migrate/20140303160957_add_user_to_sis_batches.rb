class AddUserToSisBatches < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :sis_batches, :user_id, :integer, :limit => 8
    add_foreign_key :sis_batches, :users
  end

  def self.down
    remove_foreign_key :sis_batches, :users
    remove_column :sis_batches, :user_id
  end
end
