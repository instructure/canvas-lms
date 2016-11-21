class AddDeveloperKeyRedirectUri < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :developer_keys, :redirect_uri, :string
  end

  def self.down
    remove_column :developer_keys, :redirect_uri
  end
end
