class AddJitProvisioningToAuthenticationProviders < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :account_authorization_configs, :jit_provisioning, :bool, default: false, null: false
  end
end
