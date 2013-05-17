class CreateRoles < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :enrollments, :role_name, :string

    create_table :roles do |t|
      t.string :name, :null => false
      t.string :base_role_type, :null => false
      t.integer :account_id, :null => false, :limit => 8
      t.string :workflow_state
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end
    add_foreign_key :roles, :accounts
    add_index :roles, [:name], :name => "index_roles_on_name"
    add_index :roles, [:account_id], :name => "index_roles_on_account_id"
  end

  def self.down
    remove_column :enrollments, :role_name

    drop_table :roles
  end
end
