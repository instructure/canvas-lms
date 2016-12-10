class DropCommunicationChannelPushColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :communication_channels, :access_token_id
    remove_column :communication_channels, :internal_path
  end

  def down
    add_column :communication_channels, :access_token_id, :integer, limit: 8
    add_column :communication_channels, :internal_path, :string
    add_foreign_key :communication_channels, :access_tokens
  end
end
