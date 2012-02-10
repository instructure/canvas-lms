class DropUserCreationColumns < ActiveRecord::Migration
  def self.up
    remove_index :users, 'users_sis_creation'
    remove_column :users, :creation_unique_id
    remove_column :users, :creation_sis_batch_id
    remove_column :users, :creation_email
  end

  def self.down
    add_column :users, :creation_email, :string
    add_column :users, :creation_sis_batch_id, :string
    add_column :users, :creation_unique_id, :string
    add_index :users, [:creation_unique_id, :creation_sis_batch_id], :name => "users_sis_creation"
  end
end
