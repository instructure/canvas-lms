class AddPushColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :developer_keys, :sns_arn, :string
    add_column :communication_channels, :access_token_id, :integer, limit: 8
    add_column :communication_channels, :internal_path, :string
    add_foreign_key :communication_channels, :access_tokens
  end

  def self.down
    remove_column :developer_keys, :sns_arn
    remove_column :communication_channels, :access_token_id
    remove_column :communication_channels, :internal_path
  end
end
