class AddAssignmentPostColumns < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :assignments, :post_to_sis, :boolean
    add_column :assignments, :integration_id, :string

    add_index :assignments, :integration_id, unique: true
  end

  def self.down
    remove_index :assignments, :integration_id
    
    remove_column :assignments, :post_to_sis
    remove_column :assignments, :integration_id
  end
end
