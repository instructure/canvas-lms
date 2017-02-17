class AddAccountAuthorizationConfigLastFailure < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_authorization_configs, :last_timeout_failure, :datetime
  end

  def self.down
    remove_column :account_authorization_configs, :last_timeout_failure
  end
end
