class AddGroupSisColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :groups, :sis_source_id, :string
    add_column :groups, :sis_name, :string
    add_column :groups, :sis_batch_id, :string

    add_column :group_memberships, :sis_batch_id, :string
  end

  def self.down
    remove_column :groups, :sis_source_id
    remove_column :groups, :sis_name
    remove_column :groups, :sis_batch_id

    remove_column :group_memberships, :sis_batch_id
  end
end
