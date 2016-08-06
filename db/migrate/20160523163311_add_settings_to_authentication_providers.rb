class AddSettingsToAuthenticationProviders < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :account_authorization_configs, :settings, :json, default: {}, null: false
  end
end
