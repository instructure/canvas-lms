class AddAccountAuthorizationConfigLoginAttribute < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_authorization_configs, :login_attribute, :text
  end

  def self.down
    remove_column :account_authorization_configs, :login_attribute
  end
end
