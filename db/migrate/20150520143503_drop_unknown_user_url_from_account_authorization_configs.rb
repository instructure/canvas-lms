class DropUnknownUserUrlFromAccountAuthorizationConfigs < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :account_authorization_configs, :unknown_user_url
  end

  def down
    add_column :account_authorization_configs, :unknown_user_url, :string
  end
end
