class AddAccessTokenCountToDeveloperKeys < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :developer_keys, :access_token_count, :integer, :default => 0, :null => false
  end
end
