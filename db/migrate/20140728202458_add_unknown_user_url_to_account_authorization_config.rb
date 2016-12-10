class AddUnknownUserUrlToAccountAuthorizationConfig < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :account_authorization_configs, :unknown_user_url, :string
  end
end
