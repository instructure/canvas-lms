class DropLdapAuthSettingsFromAacs < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :account_authorization_configs, :login_handle_name
    remove_column :account_authorization_configs, :change_password_url
  end

  def down
    add_column :account_authorization_configs, :login_handle_name, :string
    add_column :account_authorization_configs, :change_password_url, :string
  end
end
