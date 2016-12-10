class AddIconUrlToDeveloperKeys < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    add_column :developer_keys, :icon_url, :string
  end

  def self.down
    remove_column :developer_keys, :icon_url
  end
end
