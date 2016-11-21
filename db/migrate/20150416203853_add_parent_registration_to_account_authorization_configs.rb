class AddParentRegistrationToAccountAuthorizationConfigs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_authorization_configs, :parent_registration, :boolean, default: false, null: false
  end

  def self.down
    remove_column :account_authorization_configs, :parent_registration
  end
end
