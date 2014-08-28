class AddTrustedToDeveloperKeys < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :developer_keys, :trusted, :boolean
  end

  def self.down
    remove_column :developer_keys, :trusted
  end
end
